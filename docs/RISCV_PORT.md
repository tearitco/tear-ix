# TEAR-IX RISC-V Port

The RISC-V port reuses the **rvemu stubs** from the RVLV_EMUL project to boot
TEAR-IX on RISC-V hardware or emulation.

## Background

The parent project `1.RVEM/RVLV_EMUL/` contains:
- **rvemu**: A RISC-V (RV64GC) emulator for QEMU virt machine, written in C
- **syscall ABI**: Linux-compatible syscalls with FD mapping and `spawn_elf`
- **VirtIO MMIO**: Block device, UART, 9p filesystem
- **prisc+x VM**: A minimal PAL VM (`.pal` assembly) that runs as bare-metal

These components serve as the "stubs" — the minimal infrastructure layer that
TEAR-IX needs to boot on RISC-V.

## Architecture

```
TEAR-IX RISC-V
├── squashfs/live filesystem  (same as x86 ISO, RISC-V compatible packages)
├── vmlinuz                   (RISC-V Linux kernel — from Buildroot/RVLV)
├── initramfs                 (TEAR-IX init + BusyBox, stripped for RISC-V)
└── rvemu stubs               (from ../1.RVEM/RVLV_EMUL)
    ├── src/syscall.c         # FD mapping, spawn_elf, I/O
    ├── src/virtio.c          # Disk access
    ├── src/uart.c            # Console I/O
    └── build/main            # Emulator binary
```

## How It Works

1. **rvemu** loads the RISC-V Linux kernel + TEAR-IX squashfs as VirtIO disk
2. The kernel boots with `init=/sbin/tear-ix-init` (TEAR-IX's custom init)
3. Custom syscalls (`SYS_SPAWN` = 400) are used to launch processes
4. `spawn_elf(path, args...)` from RVLV's syscall ABI handles process launching
5. If full Linux isn't feasible, **prisc+x.c** runs as a bare-metal VM:
   - Compiled with `riscv64-unknown-elf-gcc` (or RVLV's musl cross-compiler)
   - Runs on rvemu directly, using the same syscall stubs

## Build

```bash
make riscv    # from project root

# This:
# 1. Builds rvemu (or uses prebuilt from ../1.RVEM/RVLV_EMUL/build/main)
# 2. Copies the squashed TEAR-IX rootfs (rebuilt for riscv64)
# 3. Assembles a RISC-V ELF initramfs with TEAR-IX branding
# 4. Runs the whole thing on rvemu
```

## Stubbing the RVEMU Components

The stubs are in `riscv/stubs/` and are derived (or symlinked) from RVLV_EMUL:

| Stub File | Source in RVLV_EMUL | Purpose |
|-----------|---------------------|---------|
| `syscall_stubs.c` | `src/syscall.c` | FD mapping + spawn_elf |
| `fd_map.h` | `includes/cpu.h` (SYS_* constants) | Syscall number defs |
| `elf_loader.c` | `src/cpu.c` (load_elf) | Load PE/ELF binaries |
| `virtio_blk.c` | `src/virtio.c` | Disk I/O for squashfs |

The RISC-V port uses:
- **Linux syscall ABI**: write=64, read=63, exit=93, brk=214, open=1024, close=57
  (from `RVLV_EMUL/includes/cpu.h:16-25`)
- **Custom op protocol**: `spawn_elf(path, args...)` (syscall 400)
- **VirtIO MMIO** at QEMU virt addresses (from `RVLV_EMUL/includes/memmap.h`)

## Package Differences (RISC-V)

The RISC-V build uses a `riscv64` variant of the package list:

```
iso/config/packages.list.riscv64
```

Packages that aren't available on RISC-V (e.g., `x86-only` binaries) are
excluded, and `gcc-riscv64-linux-gnu` is included for any native compilation
needs.

## Testing

```bash
# Run TEAR-IX on rvemu (RISC-V emulation)
./riscv/build/run_riscv.sh

# Verify boot + init
# Expected output:
#   "TEAR-IX ; by tear-it co" on boot splash
#   "Welcome to TEAR-IX RISC-V" on console
```
