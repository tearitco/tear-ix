#!/usr/bin/env bash
# build_riscv_initramfs.sh - Assemble TEAR-IX initramfs for RISC-V
set -euo pipefail

RISCV_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
BUILD_DIR="${RISCV_DIR}/build"

echo "Building TEAR-IX RISC-V initramfs..."

mkdir -p "${BUILD_DIR}/initramfs"

# Copy busybox from the RISC-V rootfs
RV_ROOTFS="${RISCV_DIR}/../1.RVEM/RVLV_EMUL/buildroot/output/images/rootfs.ext2"
if [ -f "$RV_ROOTFS" ]; then
    # Extract busybox
    mkdir -p "${BUILD_DIR}/rootfs"
    # We'd mount/extract here in a real build
    echo "  Found RISC-V rootfs: ${RV_ROOTFS}"
fi

# Create TEAR-IX init script
mkdir -p "${BUILD_DIR}/initramfs/sbin"
cat > "${BUILD_DIR}/initramfs/sbin/tear-ix-init" << 'INIT'
#!/bin/sh
# TEAR-IX RISC-V init - "tear-ix ; by tear-it co"
export PS1='TEAR-IX \u@tear-ix:~# '
export PATH=/sbin:/bin:/usr/sbin:/usr/bin

echo ""
echo "========================================"
echo "  tear-ix ; by tear-it co"
echo "  RISC-V Port (rvemu stubs)"
echo "  Version: 00.00"
echo "========================================"
echo ""

# Mount essential filesystems
mount -t proc proc /proc 2>/dev/null || true
mount -t sysfs sysfs /sys 2>/dev/null || true
mount -t devtmpfs devtmpfs /dev 2>/dev/null || true

echo "Welcome to TEAR-IX RISC-V"
echo ""

# Show system info
echo "Kernel: $(uname -r)"
echo "Arch: $(uname -m)"
echo ""

# Hand off to shell
exec sh
INIT
chmod +x "${BUILD_DIR}/initramfs/sbin/tear-ix-init"

# Create device nodes
mkdir -p "${BUILD_DIR}/initramfs/dev"
mknod -m 600 "${BUILD_DIR}/initramfs/dev/console" c 5 1 2>/dev/null || true
mknod -m 666 "${BUILD_DIR}/initramfs/dev/null" c 1 3 2>/dev/null || true

# Copy branding
mkdir -p "${BUILD_DIR}/initramfs/etc"
cp "${RISCV_DIR}/../branding/logos/tear-ix-logo.txt" \
   "${BUILD_DIR}/initramfs/etc/tear-ix-motd" 2>/dev/null || true

# Build cpio
cd "${BUILD_DIR}/initramfs"
find . | cpio -H newc -o > "${BUILD_DIR}/initramfs.cpio" 2>/dev/null

echo "  Initramfs created: ${BUILD_DIR}/initramfs.cpio"
