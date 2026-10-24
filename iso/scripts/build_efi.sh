#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_ROOT="$SCRIPT_DIR/../build/iso-root"
EFI_DIR="$ISO_ROOT/EFI/BOOT"
LIVE_DIR="$ISO_ROOT/live"

mkdir -p "$EFI_DIR" "$LIVE_DIR"

# GRUB early config - embeds filesystem search
cat > /tmp/grub-early.cfg << 'EOF'
search --set=iso -l TEARIXJAMMY
set root=$iso
configfile /boot/grub/grub.cfg
EOF

# GRUB standalone config (embedded in EFI binary)
cat > /tmp/grub-standalone.cfg << 'EOF'
insmod part_msdos
insmod iso9660
insmod fat
insmod ext2
insmod search
insmod configfile
insmod loopback
insmod test
insmod linux
insmod linuxefi

terminal_output console
set color_normal="light-gray/dark-gray"
set menu_color_normal="light-gray/dark-gray"
set menu_color_highlight="yellow/blue"
set timeout=10
set default=0

menuentry "TEAR-IX Live - Boot (tear-ix ; by tear-it co)" {
    search --set=root -l TEARIXJAMMY
    linux /live/vmlinuz init=/sbin/init console=ttyS0,115200n8 console=tty0
    initrd /live/initrd
}

menuentry "TEAR-IX Live - Reboot" {
    reboot
}

menuentry "TEAR-IX Live - Halt" {
    halt
}
EOF

# Build GRUB EFI binary
grub-mkimage \
    -c /tmp/grub-early.cfg \
    -o "$EFI_DIR/BOOTX64.EFI" \
    -O x86_64-efi \
    -p /boot/grub \
    part_msdos iso9660 fat ext2 search configfile linux linuxefi test loopback normal 2>&1

echo "[build_efi] GRUB EFI binary: $(ls -la "$EFI_DIR/BOOTX64.EFI" | awk '{print $5}') bytes"
