# TEAR-IX ISO Build Guide

## Prerequisites

No `sudo` access is available. The build uses:
- `genisoimage` (instead of xorriso) for ISO creation
- `grub-mkimage` (instead of grub-mkrescue) for EFI binary creation
- `mkfs.fat` + Python script for FAT ESP image creation
- `qemu-system-x86_64` + `OVMF.fd` for UEFI testing

## UEFI x86_64 ISO Build Process

### 1. Kernel and Initrd

Download a Jammy kernel package:
```bash
apt-get download linux-image-5.15.0-198-generic
dpkg-deb -x linux-image-*.deb /tmp/kernel-extract
cp /tmp/kernel-extract/boot/vmlinuz-* live/vmlinuz
```

For the initrd, either use the Ubuntu generated initrd or create a minimal one:
```bash
# Minimal busybox initrd (POC)
mkdir -p initramfs/{bin,sbin,dev,etc,proc,sys}
cp /usr/bin/busybox initramfs/bin/
# Create init script with TEAR-IX branding
# ... see riscv/scripts/build_riscv_initramfs.sh for pattern
find initramfs | cpio -H newc -o > live/initrd
```

### 2. GRUB EFI Binary

Build GRUB EFI application with embedded early config:
```bash
# Early config: search for ISO and load grub.cfg
cat > /tmp/grub-early.cfg << 'EOF'
search --set=iso -l TEARIXJAMMY
set root=$iso
configfile /boot/grub/grub.cfg
EOF

grub-mkimage \
    -c /tmp/grub-early.cfg \
    -o EFI/BOOT/BOOTX64.EFI \
    -O x86_64-efi \
    -p /boot/grub \
    part_msdos iso9660 fat ext2 search configfile linux linuxefi test loopback normal
```

### 3. FAT ESP Image

Create a FAT16 ESP containing the GRUB EFI binary:
```bash
# Create base filesystem
dd if=/dev/zero of=esp.img bs=1M count=16
mkfs.fat -F 16 -n TEARIXESP esp.img

# Inject EFI/BOOT/BOOTX64.EFI using Python script
python3 scripts/build_esp.py EFI/BOOT/BOOTX64.EFI esp.img
```

### 4. ISO Creation

```bash
genisoimage \
    -J -r -V "TEARIXJAMMY" \
    -A "TEAR-IX Live" \
    -e tear-ix_esp.img \
    -no-emul-boot \
    iso-root/
```

### 5. Testing

```bash
qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom tear-ix.iso \
    -m 1G -serial stdio -nographic
```

## Key Technical Notes

- The ESP volume label must differ from the ISO volume label to avoid device conflicts
- `grub-mkimage` (not `grub-mkstandalone`) is used to embed an early config via `-c`
- The `linuxefi` module provides EFI-compatible kernel loading
- The `initrd` command is available via the `normal` module

## Working Build

The UEFI ISO boots successfully with full TEAR-IX branding:
1. OVMF loads ESP from El Torita EFI boot entry
2. GRUB EFI runs with TEAR-IX branded menu
3. GRUB loads kernel and initrd from ISO9660 filesystem
4. Kernel boots with `root=/dev/ram0 rw init=/init console=ttyS0,115200n8`
5. Initramfs runs `/init` script with TEAR-IX branded welcome message
6. Busybox shell provides interactive shell

### Boot Parameters

The kernel command line uses:
```
root=/dev/ram0 rw init=/init console=ttyS0,115200n8
```

Key parameters:
- `root=/dev/ram0` - tells kernel to use initramfs as root
- `rw` - mount root read-write
- `init=/init` - run `/init` script from initramfs (NOT `/sbin/init`)
- `console=ttyS0,115200n8` - serial console only (removing `console=tty0` prevents output duplication/confusion)

### Init Script Requirements

The init script MUST be at `/init` (root of initramfs), not `/sbin/init`, for the kernel to find and execute it. The kernel's search order is:
1. `/init` (if `init=` specified, use that path directly)
2. `/sbin/init`
3. `/etc/init`
4. `/bin/init`

### QEMU Testing

```bash
# UEFI ISO boot test
qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom tear-ix_uefi.iso \
    -m 1G -serial stdio -nographic

# Direct kernel+initrd test (faster boot)
qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -kernel live/vmlinuz \
    -initrd live/initrd \
    -append "root=/dev/ram0 rw init=/init console=ttyS0,115200n8" \
    -m 1G -nographic -serial mon:stdio
```

## Installer Status

**No installer exists yet.** The current ISO boots to a busybox shell in RAM.

To implement installation to a virtual disk:
1. Add disk partitioning/writing tools (fdisk, parted, mkfs.ext4)
2. Create an installer script that:
   - Partitions the target disk (EFI System Partition + root partition)
   - Formats partitions (FAT32 for ESP, ext4 for root)
   - Copies root filesystem from ISO/initramfs to target
   - Installs GRUB to target EFI partition
3. Use QEMU with `-drive file=disk.img,format=raw` for testing
