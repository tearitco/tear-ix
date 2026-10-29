# TEAR-IX Agent Handoff

## Status: Complete (as of 2026-10-29)

The repository has been created at `git@github.com:tearitco/tear-ix.git`
(also accessible via `https://github.com/tearitco/tear-ix`).

### Completed Work
- Initial project scaffold with RPG fantasy branding
- UEFI boot with GRUB EFI + BusyBox init
- RISC-V port using rvemu stubs from `tearitco/RVLV_EMUL`
- ISO build infrastructure (`iso/`, `Makefile`)
- RISC-V stubs in `riscv/`
- Branding assets, docs, and build scripts

### Git Status
- Branch: `main`
- Remote: `git@github.com:tearitco/tear-ix.git`
- SSH auth is configured; no additional credentials needed
- Push command: `git push origin main`

## How to Start

```bash
cd ~/Desktop/ele-desk+cal/TEAR-IX
cat AGENTS.md           # Agent workflow & constraints
cat README.md           # Project overview
cat Makefile            # Build commands
```

## Build Commands

```bash
make iso        # Build x86_64 UEFI ISO
make riscv    # Build/run RISC-V variant on rvemu
make clean    # Remove build artifacts
make test     # Run validation checks
```

## Testing

```bash
# ISO structure tests
make test

# QEMU UEFI boot test (x86_64)
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom iso/build/tear-ix.iso

# RISC-V simulation via rvemu
make riscv
```

## Git Notes

- Branch: `main`
- Remote: `git@github.com:tearitco/tear-ix.git`
- SSH auth is configured; no additional credentials needed
- Build artifacts are gitignored (`iso/build/`, `riscv/build/`)
- Commit messages: `feat:`, `fix:`, `docs:`, `build:`, `chore:`

## Key Directories

| Purpose | Path |
|---------|------|
| ISO build config | `iso/config/` |
| Build hooks | `iso/hooks/` |
| Filesystem overlays | `iso/overlays/` |
| RISC-V stubs | `riscv/stubs/` (copies from `../1.RVEM/RVLV_EMUL/`) |
| Branding assets | `branding/` |
| Build scripts | `iso/scripts/`, `Makefile` |
| Documentation | `docs/` |

## Relationship to RVLV_EMUL

TEAR-IX borrows heavily from `1.RVEM/RVLV_EMUL/` (GitHub: `tearitco/RVLV_EMUL`):

- **rvemu stubs**: Syscall ABI, `spawn_elf` protocol, VirtIO/MMIO
- **prisc+x VM**: `.pal` VM used for minimal RISC-V runtime (where full Linux isn't feasible)
- **HDLb0/FPGA**: Discrete FPGA emulator work referenced for hardware customization

See `docs/RVLV_LEARNINGS.md` for the full mapping.

### RVLV Build Reference

The RVLV project uses these build commands:
```bash
# Build rvemu (standalone, x86_64)
gcc -O2 -std=gnu11 \
    -I"XO.SFPGA.NN/src" -Iincludes \
    -o /tmp/rvemu \
    main.c src/*.c XO.SFPGA.NN/src/fpga.c -lm

# RISC-V cross-compiler for Linux builds
riscv64-unknown-elf-gcc  # (required for some tests)
```
