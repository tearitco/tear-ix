#!/bin/bash
# build_minimal_embedded.sh - Build smallest possible TEAR-IX for embedded/CLI
# Target: ~15MB total (vs 38MB for full ISO)
# Uses EFI stub kernel (no GRUB) + minimal BusyBox initramfs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEARIX_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$TEARIX_DIR/iso/build/minimal"

echo "=== TEAR-IX Minimal Embedded Build ==="
echo "Target: <15MB bootable image (EFI stub, no GRUB, BusyBox CLI)"
echo ""

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/initramfs/bin" "$BUILD_DIR/initramfs/sbin" "$BUILD_DIR/initramfs/etc" "$BUILD_DIR/initramfs/proc" "$BUILD_DIR/initramfs/sys" "$BUILD_DIR/initramfs/dev"

# 1. Copy kernel (EFI-stub enabled)
echo "[1/4] Copying kernel..."
KERNEL_SRC="/tmp/kernel-extract/boot/vmlinuz-5.15.0-198-generic"
if [ ! -f "$KERNEL_SRC" ]; then
    echo "ERROR: Kernel not found at $KERNEL_SRC"
    echo "Extract it first: dpkg-deb -x linux-image-*.deb /tmp/kernel-extract"
    exit 1
fi
cp "$KERNEL_SRC" "$BUILD_DIR/vmlinuz"
echo "  Kernel: $(du -h "$BUILD_DIR/vmlinuz" | cut -f1)"

# 2. Build minimal initramfs (BusyBox only, no extra packages)
echo "[2/4] Building minimal initramfs..."
BUSYBOX="/usr/bin/busybox"
if [ ! -f "$BUSYBOX" ]; then
    echo "ERROR: busybox not found at $BUSYBOX"
    exit 1
fi
cp "$BUSYBOX" "$BUILD_DIR/initramfs/bin/busybox"
chmod +x "$BUILD_DIR/initramfs/bin/busybox"

# Only the essential applets for CLI/embedded use
cd "$BUILD_DIR/initramfs/bin"
for applet in sh ash ls cat echo mount umount mkdir mknod; do
    ln -sf busybox "$applet"
done

# Minimal init script with TEAR-IX branding
cat > "$BUILD_DIR/initramfs/init" << 'INIT'
#!/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin

mount -t devtmpfs devtmpfs /dev 2>/dev/null || true
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true

[ -c /dev/console ] || mknod /dev/console c 5 1
[ -c /dev/ttyS0 ] || mknod /dev/ttyS0 c 4 64

GOLD='\033[0;33m'
CRIMSON='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

printf "${PURPLE}  ============================================================\n${NC}"
printf "${PURPLE}  |                                                          |\n${NC}"
printf "${GOLD}  |     TEAR-IX minimal (embedded)                           |\n${NC}"
printf "${PURPLE}  |                                                          |\n${NC}"
printf "${CRIMSON}  |      tear-ix ; by tear-it co                             |\n${NC}"
printf "${PURPLE}  |                                                          |\n${NC}"
printf "${GOLD}  |     v00.00 | BusyBox $(busybox --version | head -1 | cut -d' ' -f1-2)        |\n${NC}"
printf "${PURPLE}  |                                                          |\n${NC}"
printf "${PURPLE}  ============================================================\n${NC}"
printf "\n"
exec /bin/sh
INIT
chmod +x "$BUILD_DIR/initramfs/init"

# Build initramfs (cpio, uncompressed for speed)
cd "$BUILD_DIR"
find initramfs | cpio -o -H newc 2>/dev/null > "$BUILD_DIR/initrd"
echo "  Initrd: $(du -h "$BUILD_DIR/initrd" | cut -f1)"

# 3. Create minimal FAT ESP image (just the kernel as EFI stub)
echo "[3/4] Creating minimal ESP..."
dd if=/dev/zero of="$BUILD_DIR/esp.img" bs=1M count=4 2>/dev/null
mkfs.fat -F16 -n "TEARIX" "$BUILD_DIR/esp.img" 2>/dev/null

# Mount and copy kernel + initrd
mkdir -p "$BUILD_DIR/mnt"
if sudo mount -o loop "$BUILD_DIR/esp.img" "$BUILD_DIR/mnt" 2>/dev/null; then
    cp "$BUILD_DIR/vmlinuz" "$BUILD_DIR/mnt/vmlinuz"
    cp "$BUILD_DIR/initrd" "$BUILD_DIR/mnt/initrd"
    sudo umount "$BUILD_DIR/mnt" 2>/dev/null
    rmdir "$BUILD_DIR/mnt" 2>/dev/null || true
    echo "  ESP: $(du -h "$BUILD_DIR/esp.img" | cut -f1)"
else
    echo "ERROR: Cannot mount ESP image"
    echo "  Try: echo 'root' | sudo -S mount -o loop $BUILD_DIR/esp.img $BUILD_DIR/mnt"
    exit 1
fi

# 4. Create the final image
echo "[4/4] Creating final image..."
cp "$BUILD_DIR/esp.img" "$BUILD_DIR/tear-ix-minimal.img"

# Also create a tiny ISO for compatibility
genisoimage \
    -o "$BUILD_DIR/tear-ix-minimal.iso" \
    -J -r -V "TEARIXMIN" \
    -b esp.img \
    -c boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    "$BUILD_DIR" 2>&1 | tail -3

echo ""
echo "=== Build Complete ==="
echo "  Minimal IMG: $(du -h "$BUILD_DIR/tear-ix-minimal.img" | cut -f1)"
echo "  Minimal ISO: $(du -h "$BUILD_DIR/tear-ix-minimal.iso" | cut -f1)"
echo ""
echo "  Boot with QEMU:"
echo "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -drive file=$BUILD_DIR/tear-ix-minimal.img,format=raw -m 512M -nographic"
echo ""
echo "  Or boot the ISO:"
echo "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom $BUILD_DIR/tear-ix-minimal.iso -m 512M -nographic"