#ifndef CPU_H
#define CPU_H

#include <stdint.h>
#include "bus.h"
#include "csr.h"
#include <stdbool.h>
#include "trap.h"

enum {
    ACC_FETCH = 0,
    ACC_LOAD  = 1,
    ACC_STORE = 2,
};

#define SYS_WRITE      64
#define SYS_READ        63
#define SYS_EXIT        93
#define SYS_BRK        214
#define SYS_OPEN      1024
#define SYS_CLOSE       57
#define SYS_FSTAT       80
#define SYS_LSEEK       62
#define SYS_FPGA_LOAD   10
#define SYS_SPAWN      400

typedef struct CPU {
    uint64_t regs[32];
    uint64_t fregs[32];
    uint64_t pc;
    uint64_t csr[4096];
    uint8_t priv;
    BUS bus;
    int reservation_valid;
    uint64_t reservation_addr;
    uint8_t reservation_size;
    uint64_t instret;
    int wfi;
    int halt;
    int halt_code;
    int sbi;
    int dump;
    int trace_trap;
    unsigned trap_prints;
    uint64_t irq_div;
    int virtio_legacy;
    uint64_t dtb_addr;
    uint64_t entry;
} CPU;

int cpu_init(CPU *cpu, uint64_t dram_size, const char *disk_path, int virtio_legacy);
void cpu_destroy(CPU *cpu);
void cpu_reset(CPU *cpu);
Trap cpu_mmu_translate(CPU *cpu, uint64_t va, int access, uint64_t *pa);
Trap cpu_fetch(CPU *cpu, uint32_t *inst, int *ilen);
Trap cpu_execute(CPU *cpu, uint32_t inst, int ilen);
int cpu_step(CPU *cpu);
void dump_registers(CPU *cpu);
Trap cpu_load(CPU *cpu, uint64_t addr, uint64_t bits, uint64_t *out);
Trap cpu_store(CPU *cpu, uint64_t addr, uint64_t bits, uint64_t value);
Trap cpu_load_bytes(CPU *cpu, uint64_t addr, void *buf, uint64_t len);
Trap cpu_store_bytes(CPU *cpu, uint64_t addr, const void *buf, uint64_t len);
Trap cpu_load_string(CPU *cpu, uint64_t addr, char *buf, uint64_t maxlen);
int cpu_pmp_ok(CPU *cpu, uint64_t addr, uint64_t nbytes, int access, int priv);
Trap exec_fp(CPU *cpu, uint32_t inst);
int sbi_ecall(CPU *cpu);
void take_trap(CPU *cpu, Trap t);
Trap check_interrupts(CPU *cpu, bool for_wfi);
uint32_t decompress(uint16_t cinst, int *illegal);
uint64_t syscall_handle(CPU *cpu, uint64_t a7, uint64_t a0, uint64_t a1, uint64_t a2,
                        uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6);

int load_image(CPU *cpu, const char *path, uint64_t default_addr, uint64_t *entry_out,
               uint64_t *size_out);
int generate_dtb(CPU *cpu, uint64_t dram_size, uint64_t initrd_start, uint64_t initrd_end,
                 const char *bootargs, uint64_t dest, uint64_t *dtb_size);
int selftest(void);

#endif
