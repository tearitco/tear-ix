# TEAR-IX Agent Instructions

See AGENTS.md and docs/ for project conventions.

## Build commands
- `make iso` - Build x86_64 UEFI ISO
- `make riscv` - Build RISC-V port using rvemu stubs

## Key constraints
- Only use the brand color palette (#FFCC00, #DC143C, #D2B48C, #9370DB)
- BusyBox init replaces systemd
- No secrets/credentials in repo
