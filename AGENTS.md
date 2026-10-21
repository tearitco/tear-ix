# TEAR-IX — Agent Workflow & Constraints

## Project Overview

TEAR-IX is a custom Ubuntu 22.04 (Jammy) derivative ISO with RPG fantasy branding,
BusyBox init, UEFI-x86 support, and a RISC-V port reusing rvemu stubs.

## Key Constraints

1. **Source-only**: All build scripts are plain bash/C/make. No GUI tools (no cubic).
2. **Minimal footprint**: BusyBox replaces systemd; only essential packages.
3. **No secrets**: Never commit keys, credentials, or private data.
4. **Naming**: Product is `TEAR-IX`, version is `00.00` (semantic versioning with
   epoch). ISO label format: `TEAR-IX-jammy-amd64`.
5. **Color scheme**: All branding must use ONLY the palette:
   - Gold/Yellow: `#FFCC00` (or `#FFD700`)
   - Crimson Red: `#DC143C`
   - Tan/Brown: `#D2B48C`
   - Royal Purple: `#9370DB`

## File Locations

| Goal | Path |
|------|------|
| ISO build config | `iso/config/` |
| Build hooks | `iso/hooks/` |
| Filesystem overlays | `iso/overlays/` |
| RISC-V stubs | `riscv/stubs/` |
| Branding assets | `branding/` |
| Build scripts | `iso/scripts/`, `Makefile` |
| Documentation | `docs/` |

## Build Commands

| Command | Description |
|---------|-------------|
| `make iso` | Build x86_64 UEFI ISO |
| `make riscv` | Build/run RISC-V variant on rvemu |
| `make clean` | Remove build artifacts |
| `make all` | Build both variants |
| `make test` | Run validation checks |

## Testing

```bash
# Verify ISO structure
make test          # Runs iso/scripts/test_iso.sh

# Boot-test on QEMU (x86_64, UEFI)
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom iso/build/tear-ix.iso

# Run on rvemu (RISC-V)
make riscv
```

## Git Notes

- The `.gitignore` excludes all build artifacts from `iso/build/` and `riscv/build/`
- `main` branch is the primary development branch
- Follow conventional commit messages: `feat:`, `fix:`, `docs:`, `build:`, `chore:`
