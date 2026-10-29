# TEAR-IX Release

## TEAR-IX.00.00 (Jammy Jellyfish)

Release artifacts for TEAR-IX x86_64 UEFI boot.

### Contents

- `tear-ix_uefi.iso` - Bootable UEFI ISO with:
  - GRUB EFI (OVMF) boot with embedded config
  - TEAR-IX branded GRUB menu (gold/crimson/tan/purple)
  - Linux kernel 5.15.0-198-generic (Jammy)
  - Minimal busybox initramfs with TEAR-IX branded init script
  - Full boot to busybox shell

### Build Environment

- Platform: Ubuntu 22.04 (Jammy) x86_64
- Kernel: 5.15.0-198-generic
- GRUB: 2.06
- UEFI firmware: OVMF

### Testing

Boot in QEMU:
```bash
qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom tear-ix_uefi.iso \
    -m 1G -serial stdio -nographic
```

### Boot Flow

1. OVMF firmware loads
2. GRUB EFI binary (BOOTX64.EFI) found in ESP
3. GRUB loads grub.cfg from ISO filesystem
4. GRUB menu displays (branded colors)
5. Kernel loads with init=/init
6. Initramfs unpacks as rootfs
7. Kernel runs /init script
8. TEAR-IX branded welcome message displays
9. Busybox shell starts

### Known Issues

- No installer yet (boots to initramfs shell)
- Virtual disk (vdisk) installation not implemented
- RISC-V port tested with rvemu emulator only
- `console=/dev/tty0` removed due to output routing issue
- No `xorriso` available; ISO built with `genisoimage`
