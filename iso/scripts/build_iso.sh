#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_ROOT="$SCRIPT_DIR/../build/iso-root"
BUILD_DIR="$SCRIPT_DIR/../build"

# Create ISO directory structure
mkdir -p "$ISO_ROOT/EFI/BOOT" "$ISO_ROOT/live" "$ISO_ROOT/boot/grub"

# Build GRUB EFI binary
"$SCRIPT_DIR/build_efi.sh"

# Copy kernel and initrd to live directory
# Kernel from downloaded package or local build
if [ -f "$BUILD_DIR/vmlinuz" ]; then
    cp "$BUILD_DIR/vmlinuz" "$ISO_ROOT/live/vmlinuz"
fi
if [ -f "$BUILD_DIR/initrd" ]; then
    cp "$BUILD_DIR/initrd" "$ISO_ROOT/live/initrd"
fi

# Create grub.cfg for the ISO
cat > "$ISO_ROOT/boot/grub/grub.cfg" << 'GRUBCFG'
set timeout=10
set default=0
terminal_output console

set color_normal="light-gray/dark-gray"
set menu_color_normal="light-gray/dark-gray"
set menu_color_highlight="yellow/blue"

insmod part_msdos
insmod iso9660
insmod search
insmod configfile

menuentry "TEAR-IX Live - Boot (tear-ix ; by tear-it co)" {
    search --set=root -l TEARIXJAMMY
    linux /live/vmlinuz root=/dev/ram0 rw init=/init console=ttyS0,115200n8
    initrd /live/initrd
}

menuentry "TEAR-IX Live - Reboot" {
    reboot
}

menuentry "TEAR-IX Live - Halt" {
    halt
}
GRUBCFG

# Build ESP image
python3 "$SCRIPT_DIR/build_esp.py" "$ISO_ROOT/EFI/BOOT/BOOTX64.EFI" "$ISO_ROOT/tear-ix_esp.img"

# Create ISO with genisoimage (El Torita EFI boot entry)
genisoimage \
    -o "$BUILD_DIR/tear-ix.iso" \
    -J -r -V "TEARIXJAMMY" \
    -A "TEAR-IX Live" \
    -e tear-ix_esp.img \
    -no-emul-boot \
    "$ISO_ROOT/" 2>&1

echo "[build_iso] ISO created: $BUILD_DIR/tear-ix.iso"
