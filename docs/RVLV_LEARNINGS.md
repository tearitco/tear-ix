# TEAR-IX — RVLV_EMUL Learnings Mapping

This document maps key learnings from the RVLV_EMUL project to TEAR-IX.
The RVLV_EMUL project lives at `../1.RVEM/RVLV_EMUL/` (relative to TEAR-IX root).

---

## 1. Architecture Philosophy: Bootstrap-First / In-House Stack

RVLV_EMUL built its own emulator (rvemu) rather than depending on QEMU for
production. TEAR-IX adapts this by:

- Building a **custom ISO** rather than depending on a GUI remaster tool (cubic).
- Using **BusyBox init** instead of systemd — mirrors RVLV's "remove dependencies"
  philosophy where each layer is small and auditable.
- Using **debootstrap + live-build** as scaffolding (like Buildroot in RVLV) —
  we strip it down to the essential packages, and any external tool has an
  in-house replacement path planned.

## 2. prisc+x VM → Minimal Runtime

RVLV's `prisc+x.c` is a 770-line PAL VM that runs `.pal` assembly. For TEAR-IX:

- On **x86**: We don't need prisc+x; the ISO runs full Ubuntu userspace.
- On **RISC-V**: prisc+x.c serves as the **bare-metal stub** — it can run on
  rvemu as a lightweight init replacement when full Linux isn't available.
- The `spawn_elf(path, args...)` custom op protocol from RVLV's syscall ABI
  (`src/syscall.c:149`) is reused as the **stubs interface** in the RISC-V port.

## 3. Syscall ABI from RVLV → RISC-V Stubs

RVLV's `src/syscall.c` implements a Linux-compatible syscall ABI with:
- FD mapping (`host_fd_map[16]`)
- `cpu_load_string` / `cpu_load_bytes` / `cpu_store_bytes` for guest↔host transfer
- `SYS_SPAWN` (syscall 400) for `spawn_elf`

**TEAR-IX RISC-V stubs adaptation:**
- Same FD mapping pattern for file I/O on the RISC-V port
- Same `spawn_elf` protocol for launching processes from the RISC-V stub layer
- Syscall numbers align with RISC-V Linux ABI (write=64, read=63, exit=93, etc.)
  as defined in `RVLV_EMUL/includes/cpu.h:16-25`

## 4. VirtIO/MMIO → ISO Disk/Installer

RVLV's `src/virtio.c` implements VirtIO MMIO block for QEMU virt. TEAR-IX:

- Uses standard VirtIO block for the ISO squashfs (same device model concept)
- Bootloader config mirrors RVLV's DTB/memory-map philosophy (fixed, known addresses)
- The `memmap.h` concept (DTB, DRAM layout) is adapted for EFI memory map

## 5. Buildroot → live-build

| RVLV_EMUL | TEAR-IX |
|-----------|---------|
| `build_buildroot.sh` → Buildroot | `make iso` → live-build auto/build |
| `output/images/Image` (kernel) | `binary/live/vmlinuz` (kernel) |
| `output/images/rootfs.ext2` | `binary/live/filesystem.squashfs` |
| `start-qemu.sh` | `bootloader/` (GRUB EFI config) |

## 6. xv6 Patch → BusyBox Init

RVLV patched `kfree()` to skip `memset` (slowdown fix). Similarly, TEAR-IX:

- Replaces systemd with BusyBox init (faster boot, smaller footprint)
- The `init=/sbin/init` boot arg pattern from RVLV's boot proof
  (`docs/RVLV_EMUL/README.md:71`) is used for TEAR-IX boot args

## 7. Test Infrastructure

RVLV's `test_emulator.sh` runs selftest, xv6, and Linux boot checks. TEAR-IX:

- `iso/scripts/test_iso.sh` verifies ISO structure, UEFI boot, and branding
- `riscv/test_riscv.sh` runs rvemu-based tests (mirrors `test_emulator.sh`)
- The `--max-inst` instruction limit concept from RVLV is adapted as a timeout
  for ISO generation to prevent runaway builds

## 8. FPGA Integration (XO.SFPGA.NN)

RVLV's XO.SFPGA.NN discrete FPGA emulator is referenced for:
- The `SYS_FPGA_LOAD` syscall (syscall 10) — could be used in RISC-V stub
  for hardware-accelerated boot verification
- The HDLb0 NAND→CPU pipeline inspires TEAR-IX's "from the ground up" build chain

## 9. Key RVLV Files to Reference

| RVLV File | TEAR-IX Use |
|-----------|-------------|
| `RVLV_EMUL/src/syscall.c` | RISC-V stubs (FD mapping, spawn_elf) |
| `RVLV_EMUL/includes/cpu.h` | Syscall number constants |
| `RVLV_EMUL/0.hdl0+prisc-bootstrap/prisc+x.c` | Bare-metal stub VM for RISC-V |
| `RVLV_EMUL/build.sh` | Build script pattern (GCC, no CMake) |
| `RVLV_EMUL/test_emulator.sh` | Test script pattern (bash, set -e) |
| `RVLV_EMUL/buildroot/` | Reference for minimal package selection |
