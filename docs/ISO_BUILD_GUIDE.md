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

The POC UEFI ISO boots successfully:
1. OVMF loads ESP from El Torita EFI boot entry
2. GRUB EFI runs with TEAR-IX branded menu
3. GRUB loads kernel and initrd from ISO9660 filesystem
4. Kernel boots and initramfs runs TEAR-IX init script
