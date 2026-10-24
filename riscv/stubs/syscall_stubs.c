#include "cpu.h"
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <string.h>

static int host_fd_map[16];
static int host_fd_count = 3;

static int map_host_fd(int host_fd) {
    if (host_fd < 0) return -1;
    for (int i = 0; i < 16; i++) {
        if (host_fd_map[i] == host_fd) return i;
    }
    if (host_fd_count < 16) {
        host_fd_map[host_fd_count] = host_fd;
        return host_fd_count++;
    }
    return -1;
}

static int get_host_fd(int guest_fd) {
    if (guest_fd < 0 || guest_fd >= 16) return -1;
    return host_fd_map[guest_fd];
}

static void syscall_init_fds() {
    for (int i = 0; i < 16; i++) host_fd_map[i] = -1;
    host_fd_map[0] = 0;
    host_fd_map[1] = 1;
    host_fd_map[2] = 2;
    host_fd_count = 3;
}

static uint64_t do_write(CPU *cpu, uint64_t fd, uint64_t buf, uint64_t count) {
    (void)cpu;
    int hfd = get_host_fd(fd);
    if (hfd < 0) return (uint64_t)(-EBADF);
    
    uint8_t *data = malloc(count);
    if (!data) return (uint64_t)(-ENOMEM);
    
    Trap t = cpu_load_bytes(cpu, buf, data, count);
    if (t.taken) {
        free(data);
        return (uint64_t)(-EFAULT);
    }
    
    ssize_t written = write(hfd, data, count);
    free(data);
    if (written < 0) return (uint64_t)(-errno);
    return (uint64_t)written;
}

static uint64_t do_read(CPU *cpu, uint64_t fd, uint64_t buf, uint64_t count) {
    (void)cpu;
    int hfd = get_host_fd(fd);
    if (hfd < 0) return (uint64_t)(-EBADF);
    
    uint8_t *data = malloc(count);
    if (!data) return (uint64_t)(-ENOMEM);
    
    ssize_t read_bytes = read(hfd, data, count);
    if (read_bytes < 0) {
        free(data);
        return (uint64_t)(-errno);
    }
    
    Trap t = cpu_store_bytes(cpu, buf, data, read_bytes);
    free(data);
    if (t.taken) return (uint64_t)(-EFAULT);
    return (uint64_t)read_bytes;
}

static uint64_t do_open(CPU *cpu, uint64_t pathname, uint64_t flags, uint64_t mode) {
    (void)cpu;
    char *path = malloc(256);
    if (!path) return (uint64_t)(-ENOMEM);
    
    Trap t = cpu_load_string(cpu, pathname, path, 256);
    if (t.taken) {
        free(path);
        return (uint64_t)(-EFAULT);
    }
    
    int hfd = open(path, (int)flags, (mode_t)mode);
    free(path);
    if (hfd < 0) return (uint64_t)(-errno);
    return (uint64_t)map_host_fd(hfd);
}

static uint64_t do_close(uint64_t fd) {
    int hfd = get_host_fd(fd);
    if (hfd < 0) return (uint64_t)(-EBADF);
    int rc = close(hfd);
    host_fd_map[fd] = -1;
    if (rc < 0) return (uint64_t)(-errno);
    return 0;
}

static uint64_t do_fstat(CPU *cpu, uint64_t fd, uint64_t statbuf) {
    int hfd = get_host_fd(fd);
    if (hfd < 0) return (uint64_t)(-EBADF);
    
    struct stat stbuf;
    if (fstat(hfd, &stbuf) < 0) return (uint64_t)(-errno);
    
    uint64_t buf[16];
    buf[0] = (uint64_t)stbuf.st_dev;
    buf[1] = (uint64_t)stbuf.st_ino;
    buf[2] = (uint64_t)stbuf.st_mode;
    buf[3] = (uint64_t)stbuf.st_nlink;
    buf[4] = (uint64_t)stbuf.st_uid;
    buf[5] = (uint64_t)stbuf.st_gid;
    buf[6] = (uint64_t)stbuf.st_rdev;
    buf[7] = (uint64_t)stbuf.st_size;
    buf[8] = (uint64_t)stbuf.st_blksize;
    buf[9] = (uint64_t)stbuf.st_blocks;
    buf[10] = (uint64_t)stbuf.st_atime;
    buf[11] = 0;
    buf[12] = (uint64_t)stbuf.st_mtime;
    buf[13] = 0;
    buf[14] = (uint64_t)stbuf.st_ctime;
    buf[15] = 0;
    
    Trap t = cpu_store_bytes(cpu, statbuf, (uint8_t*)buf, sizeof(buf));
    if (t.taken) return (uint64_t)(-EFAULT);
    return 0;
}

static uint64_t do_lseek(uint64_t fd, uint64_t offset, uint64_t whence) {
    int hfd = get_host_fd(fd);
    if (hfd < 0) return (uint64_t)(-EBADF);
    off_t result = lseek(hfd, (off_t)offset, (int)whence);
    if (result < 0) return (uint64_t)(-errno);
    return (uint64_t)result;
}

static uint64_t do_brk(CPU *cpu) {
    (void)cpu;
    return cpu->bus.dram.size;
}

static uint64_t do_spawn(CPU *cpu, uint64_t pathname) {
    (void)cpu;
    char *path = malloc(256);
    if (!path) return (uint64_t)(-ENOMEM);
    
    Trap t = cpu_load_string(cpu, pathname, path, 256);
    if (t.taken) {
        free(path);
        return (uint64_t)(-EFAULT);
    }
    
    /* For now, just log and return success - full ELF loading needs more infrastructure */
    fprintf(stderr, "[SYS_SPAWN] Would load: %s\n", path);
    free(path);
    return 0;  /* Return 0 for success (placeholder) */
}

static uint64_t do_fpga_load(CPU *cpu, uint64_t path_addr, uint64_t load_addr) {
    (void)cpu;
    (void)load_addr;
    char path[256];
    Trap t = cpu_load_string(cpu, path_addr, path, 256);
    if (t.taken) {
        return (uint64_t)(-EFAULT);
    }
    if (fpga_bs_load(&cpu->bus.fpga_bs, path) < 0) {
        return (uint64_t)(-ENOENT);
    }
    if (fpga_bs_apply(&cpu->bus.fpga, &cpu->bus.fpga_bs) != 0) {
        return (uint64_t)(-EINVAL);
    }
    cpu->bus.fpga_loaded = 1;
    return 0;
}

uint64_t syscall_handle(CPU *cpu, uint64_t a7, uint64_t a0, uint64_t a1, uint64_t a2,
                        uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6) {
    (void)a3; (void)a4; (void)a5; (void)a6;
    static int initialized = 0;
    if (!initialized) {
        syscall_init_fds();
        initialized = 1;
    }
    
    switch (a7) {
        case SYS_WRITE:   return do_write(cpu, a0, a1, a2);
        case SYS_READ:    return do_read(cpu, a0, a1, a2);
        case SYS_OPEN:    return do_open(cpu, a0, a1, a2);
        case SYS_CLOSE:   return do_close(a0);
        case SYS_FSTAT:   return do_fstat(cpu, a0, a1);
        case SYS_LSEEK:   return do_lseek(a0, a1, a2);
        case SYS_BRK:     return do_brk(cpu);
        case SYS_SPAWN:   return do_spawn(cpu, a0);
        case SYS_FPGA_LOAD: return do_fpga_load(cpu, a0, a1);
        case SYS_EXIT:    cpu->halt = 1; cpu->halt_code = a0; return 0;
        default:          return (uint64_t)(-ENOSYS);
    }
}
