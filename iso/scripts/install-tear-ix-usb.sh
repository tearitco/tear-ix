#!/bin/bash
# install-tear-ix-usb.sh - Write TEAR-IX ISO to a USB drive
# This script erases the current USB contents and writes TEAR-IX directly
# Usage:
#   ./install-tear-ix-usb.sh /dev/sdb           # Write to USB drive
#   ./install-tear-ix-usb.sh /dev/sdb --verify  # Verify after write
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEARIX_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ISO_FILE="${TEARIX_DIR}/ship/tear-ix_uefi.iso"

DRIVE="${1:-}"
VERIFY="${2:-}"

if [ -z "$DRIVE" ]; then
    echo "Usage: $0 <usb-device> [--verify]"
    echo ""
    echo "Examples:"
    echo "  $0 /dev/sdb"
    echo "  $0 /dev/sdb --verify"
    echo ""
    echo "Available block devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS 2>/dev/null || true
    exit 1
fi

# Safety check: ensure the drive is not the system disk
if [ "$DRIVE" = "/dev/sda" ] || [ "$DRIVE" = "/dev/sda1" ] || [ "$DRIVE" = "/dev/sda2" ]; then
    echo "ERROR: Refusing to write to system disk ($DRIVE)"
    exit 1
fi

# Check if the drive exists
if [ ! -b "$DRIVE" ]; then
    echo "ERROR: $DRIVE is not a block device"
    exit 1
fi

# Check if ISO exists
if [ ! -f "$ISO_FILE" ]; then
    echo "ERROR: TEAR-IX ISO not found at $ISO_FILE"
    echo "Build it first: make iso"
    exit 1
fi

# Confirm destructive action
echo "============================================"
echo "  TEAR-IX USB Installer"
echo "============================================"
echo ""
echo "  ISO:   $ISO_FILE"
echo "  Size:  $(du -h "$ISO_FILE" | cut -f1)"
echo "  Drive: $DRIVE"
echo ""
echo "  WARNING: This will ERASE all data on $DRIVE"
echo ""

# Show current contents
echo "Current device contents:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS "$DRIVE" 2>/dev/null || true
echo ""

read -p "  Continue? (y/N): " -n 1 -r CONFIRM
echo ""
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "  Cancelled."
    exit 0
fi

# Unmount any mounted partitions
echo ""
echo "=== Unmounting any mounted partitions ==="
for part in "${DRIVE}"*; do
    if [ -b "$part" ] && mount | grep -q "$part"; then
        echo "  Unmounting $part..."
        sudo umount "$part" 2>/dev/null || true
    fi
done

# Write the ISO to the USB drive
echo ""
echo "=== Writing TEAR-IX to $DRIVE ==="
echo "  This may take a few minutes..."
sudo dd if="$ISO_FILE" of="$DRIVE" bs=4M status=progress conv=fsync

# Sync and wait
sync
sleep 2

# Verify
if [ "$VERIFY" = "--verify" ]; then
    echo ""
    echo "=== Verifying write ==="
    echo "  Comparing ISO checksum with written device..."
    ISO_MD5=$(md5sum "$ISO_FILE" | awk '{print $1}')
    DEV_MD5=$(sudo dd if="$DRIVE" bs=4M status=none | md5sum | awk '{print $1}')
    
    echo "  ISO MD5:    $ISO_MD5"
    echo "  Device MD5: $DEV_MD5"
    
    if [ "$ISO_MD5" = "$DEV_MD5" ]; then
        echo "  ✓ Verification PASSED"
    else
        echo "  ✗ Verification FAILED"
        exit 1
    fi
fi

echo ""
echo "=== TEAR-IX USB installation complete ==="
echo ""
echo "  Boot from this USB by selecting it in your"
echo "  firmware/UEFI boot menu (usually F12 or Esc)."
echo ""
echo "  TEAR-IX GRUB menu will appear with options for:"
echo "    - Server (headless, BusyBox init)"
echo "    - Desktop (GUI, XFCE)"
echo "    - RISC-V (rvemu stubs)"
echo ""