# TEAR-IX Agent Handoff

## Status Summary

The TEAR-IX project is a custom Ubuntu 22.04 (Jammy) derivative with:
- RPG fantasy branding (shield/seal, potions, quills, fairy dust theme)
- BusyBox init (no systemd)
- UEFI-x86_64 boot via GRUB EFI
- RISC-V port using rvemu stubs (borrowed from `../1.RVEM/RVLV_EMUL/`)
- Git repo at `git@github.com:tearitco/tear-ix.git` (main branch)
- 3 commits so far: initial scaffold, WIP boot, UEFI boot fix

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
- No credentials are stored locally. Use your own GitHub SSH key or HTTPS token.
- Build artifacts are gitignored (`iso/build/`, `riscv/build/`)

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

## Constraints

1. Source-only: plain bash/C/make, no GUI tools (no cubic)
2. Minimal footprint: BusyBox replaces systemd
3. No secrets in repo
4. Color palette: `#FFCC00` (gold), `#DC143C` (crimson), `#D2B48C` (tan), `#9370DB` (purple)
5. Version: `00.00` (epoch-based)
6. ISO label: `TEAR-IX-jammy-amd64`

## Relationship to 1.RVEM

TEAR-IX reuses rvemu stubs from `1.RVEM/RVLV_EMUL/` for RISC-V:
- Syscall ABI
- spawn_elf protocol
- VirtIO/MMIO infrastructure

The RVLV project also has the `.pal` VM system for minimal runtime needs.
