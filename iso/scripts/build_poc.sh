#!/usr/bin/env bash
# build_poc.sh - Proof-of-concept ISO builder (no sudo needed)
# Creates a minimal TEAR-IX bootable ISO using GRUB EFI + genisoimage
# Tests: UEFI boot chain, GRUB menu, TEAR-IX branding
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${ISO_DIR}/build"
POC_DIR="${BUILD_DIR}/poc"

echo "=== TEAR-IX.00.00 POC ISO Build ==="

VARIANT="${1:-headless}"
echo "Variant: ${VARIANT}"
echo ""

# Clean
rm -rf "${POC_DIR}"
mkdir -p "${POC_DIR}/boot/grub"
mkdir -p "${POC_DIR}/live"
mkdir -p "${POC_DIR}/tearix"/{bin,sbin,etc,usr/bin,proc,sys,dev}

# Find busybox
BUSYBOX_BIN="/usr/bin/busybox"
if [ ! -f "$BUSYBOX_BIN" ]; then
    echo "ERROR: busybox not found at /usr/bin/busybox"
    exit 1
fi

# Copy busybox + symlinks
cp "$BUSYBOX_BIN" "${POC_DIR}/tearix/bin/busybox"
chmod +x "${POC_DIR}/tearix/bin/busybox"
cd "${POC_DIR}/tearix/bin"
for applet in sh ls cat echo mount umount mkdir rmdir chmod chown ps df env printenv date uname; do
    ln -sf busybox "$applet"
done

# TEAR-IX init script
cat > "${POC_DIR}/tearix/sbin/init" << 'INIT'
#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin

GOLD='\033[0;33m'
CRIMSON='\033[0;31m'
TAN='\033[0;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true

[ -c /dev/console ] || mknod /dev/console c 5 1
[ -c /dev/null ] || mknod /dev/null c 1 3
[ -c /dev/tty0 ] || mknod /dev/tty0 c 4 0
[ -c /dev/ttyS0 ] || mknod /dev/ttyS0 c 4 64

echo ""
echo -e "${PURPLE}  ============================================================${NC}"
echo -e "${PURPLE}  |                                                          |${NC}"
echo -e "${GOLD}  |     TEAR-IX                                              |${NC}"
echo -e "${PURPLE}  |                                                          |${NC}"
echo -e "${CRIMSON}  |      tear-ix ; by tear-it co                            |${NC}"
echo -e "${PURPLE}  |                                                          |${NC}"
echo -e "${GOLD}  |     Version 00.00  |  Jammy Jellyfish                    |${NC}"
echo -e "${PURPLE}  |                                                          |${NC}"
echo -e "${TAN}  |     A lite Ubuntu 22.04 remix (RPG fantasy themed)       |${NC}"
echo -e "${PURPLE}  |                                                          |${NC}"
echo -e "${PURPLE}  ============================================================${NC}"
echo ""
echo -e "${CRIMSON}  Boot complete. Welcome to TEAR-IX.${NC}"
echo -e "${GOLD}  root@tear-ix:~ ${NC}"
echo ""

exec sh
INIT
chmod +x "${POC_DIR}/tearix/sbin/init"

# Minimal etc
echo "tear-ix" > "${POC_DIR}/tearix/etc/hostname"
echo "127.0.0.1 localhost tear-ix" > "${POC_DIR}/tearix/etc/hosts"

# Build initramfs (cpio)
echo "Building initramfs..."
mkdir -p "${POC_DIR}/live"
(cd "${POC_DIR}/tearix" && find . | cpio -o -H newc) > "${POC_DIR}/live/initrd" 2>/dev/null
echo "  Initramfs size: $(du -h "${POC_DIR}/live/initrd" | cut -f1)"

# Try to find a readable kernel
KERNEL_PATH=""
for k in /boot/vmlinuz-*; do
    if [ -f "$k" ] && [ -r "$k" ]; then
        KERNEL_PATH="$k"
        echo "Using kernel: ${KERNEL_PATH}"
        cp "$KERNEL_PATH" "${POC_DIR}/live/vmlinuz"
        break
    fi
done
if [ -z "$KERNEL_PATH" ]; then
    echo "  No readable kernel found - will test GRUB menu only"
fi

# GRUB config
cat > "${POC_DIR}/boot/grub/grub.cfg" << 'GRUBCFG'
set timeout=10
set default=0

# TEAR-IX color scheme: Gold, Crimson, Tan, Purple
if loadfont /boot/grub/fonts/unicode.pf2; then
    set gfxmode=auto
    insmod gfxterm
    terminal gfxterm
fi

insmod part_msdos
insmod ext2
insmod iso9660
insmod loopback

menuentry "TEAR-IX Live - Boot (tear-ix ; by tear-it co)" {
    linux /live/vmlinuz root=/dev/ram0 init=/sbin/init console=ttyS0,115200n8 console=tty0
    initrd /live/initrd
}

menuentry "TEAR-IX Live - Reboot" {
    reboot
}

menuentry "TEAR-IX Live - Halt" {
    halt
}
GRUBCFG

# Copy fonts (for GRUB gfxterm)
if [ -f /usr/share/grub/fonts/unicode.pf2 ]; then
    cp /usr/share/grub/fonts/unicode.pf2 ${POC_DIR}/boot/grub/fonts/ 2>/dev/null || true
    mkdir -p ${POC_DIR}/boot/grub/fonts/
    cp /usr/share/grub/fonts/unicode.pf2 ${POC_DIR}/boot/grub/fonts/
fi

# Build GRUB standalone EFI binary
echo "Building GRUB EFI standalone..."
mkdir -p "${POC_DIR}/EFI/BOOT"
grub-mkstandalone \
    --format=x86_64-efi \
    --output="${POC_DIR}/EFI/BOOT/BOOTX64.EFI" \
    -- \
    "linux /live/vmlinuz root=/dev/ram0 init=/sbin/init console=ttyS0,115200n8 console=tty0" \
    "initrd /live/initrd" \
    "configfile /boot/grub/grub.cfg" 2>&1

if [ ! -f "${POC_DIR}/EFI/BOOT/BOOTX64.EFI" ]; then
    echo "grub-mkstandalone failed, trying direct grub-mkimage..."
    grub-mkimage --format=x86_64-efi --output="${POC_DIR}/EFI/BOOT/BOOTX64.EFI" \
        --prefix="/boot/grub" part_gpt part_msdos ext2 iso9660 loopback biosdisk \
        configfile linux initrd echo help ls cat halt reboot 2>&1
fi

if [ -f "${POC_DIR}/EFI/BOOT/BOOTX64.EFI" ]; then
    echo "  EFI binary: $(ls -lh "${POC_DIR}/EFI/BOOT/BOOTX64.EFI" | awk '{print $5}')"
else
    echo "ERROR: Could not create EFI binary"
    exit 1
fi

# Create UEFI bootable disk image (FAT-formatted, tested with OVMF)
echo "Creating UEFI disk image..."
UEFI_IMG="${BUILD_DIR}/tear-ix_uefi.img"
mkdir -p "${POC_DIR}/efi"

# Create a FAT16 image for EFI boot
dd if=/dev/zero of="${UEFI_IMG}" bs=1M count=64 2>/dev/null
# Use mtools to copy files to the FAT image
if command -v mcopy &>/dev/null; then
    mformat -i "${UEFI_IMG}" ::
    mcopy -i "${UEFI_IMG}" "${POC_DIR}/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/
    mcopy -i "${UEFI_IMG}" "${POC_DIR}/boot/grub/grub.cfg" ::/boot/grub/ 2>/dev/null || true
    mcopy -i "${UEFI_IMG}" "${POC_DIR}/live/vmlinuz" ::/live/ 2>/dev/null || true
    mcopy -i "${UEFI_IMG}" "${POC_DIR}/live/initrd" ::/live/ 2>/dev/null || true
    mcopy -i "${UEFI_IMG}" "${POC_DIR}/tearix" ::/tearix/ 2>/dev/null || true
else
    echo "mtools not available, using FAT filesystem mount"
    # Create FAT image manually
    dd if=/dev/zero of="${UEFI_IMG}" bs=1M count=64 2>/dev/null
    mkfs.fat -F16 -n "TEARIX" "${UEFI_IMG}" 2>/dev/null || {
        # Fallback: just use the raw file structure with grub-mkrescue alternative
        echo "Cannot create FAT filesystem, trying genisoimage..."
    }
    if command -v mcopy &>/dev/null; then
        mcopy -i "${UEFI_IMG}" -o "${POC_DIR}/EFI/BOOT/BOOTX64.EFI" ::/EFI/BOOT/
    fi
fi

if [ -f "${UEFI_IMG}" ]; then
    echo "  UEFI image: $(ls -lh "${UEFI_IMG}" | awk '{print $9}') $(du -h "${UEFI_IMG}" | cut -f1)"
fi

# Also create a genisoimage-based ISO (hybrid)
echo "Creating hybrid ISO with genisoimage..."
ISO_OUTPUT="${BUILD_DIR}/tear-ix_poc.iso"

# Create ISO with EFI boot support using genisoimage
genisoimage \
    -o "${ISO_OUTPUT}" \
    -J -r -V "TEAR-IX-JAMMY" \
    -b EFI/BOOT/BOOTX64.EFI \
    -c boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/BOOT/BOOTX64.EFI \
    -no-emul-boot \
    -gptmbr_image \
    "${POC_DIR}" 2>&1 || {
    echo "genisoimage EFI failed, trying without EFI..."
    # Fallback: simple ISO without EFI
    mkisofs -o "${ISO_OUTPUT}" -J -r -V "TEAR-IX-JAMMY" "${POC_DIR}" 2>&1
}

if [ -f "$ISO_OUTPUT" ]; then
    echo ""
    echo "=== POC ISO built ==="
    echo "Output: ${ISO_OUTPUT}"
    ls -lh "$ISO_OUTPUT"
    echo ""
    echo "=== Test with QEMU (UEFI) ==="
    echo "For UEFI disk image test:"
    echo "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -drive format=raw,file=${UEFI_IMG} -m 512M -serial stdio"
    echo ""
    echo "For ISO test (BIOS or UEFI):"
    echo "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom ${ISO_OUTPUT} -m 512M -serial stdio"
else
    echo "ERROR: ISO build failed"
    # List what we have
    echo "Build dir contents:"
    find ${POC_DIR} -type f | head -20
    exit 1
fi
