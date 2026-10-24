#!/usr/bin/env bash
# build_riscv.sh - Build/run TEAR-IX on RISC-V using rvemu stubs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RISCV_DIR="$(dirname "$SCRIPT_DIR")"
RVEMU_DIR="${RISCV_DIR}/../../1.RVEM/RVLV_EMUL"
# Resolve relative to script location (TEAR-IX -> ../1.RVEM/RVLV_EMUL)
if [ ! -d "$RVEMU_DIR" ]; then
    RVEMU_DIR="$(cd "${RISCV_DIR}/../../1.RVEM/RVLV_EMUL" 2>/dev/null && pwd)"
fi

echo "=== TEAR-IX RISC-V Port Build ==="
echo ""

# Check if rvemu exists
RVEMU_BIN="${RVEMU_DIR}/build/main"
if [ ! -f "$RVEMU_BIN" ]; then
    echo "rvemu binary not found at: ${RVEMU_BIN}"
    echo "Building rvemu..."
    if [ -f "${RVEMU_DIR}/build.sh" ]; then
        cd "${RVEMU_DIR}" && ./build.sh
    else
        echo "ERROR: Cannot find rvemu build.sh"
        exit 1
    fi
fi

# Copy stubs from RVEMU
echo "Copying rvemu stubs..."
mkdir -p "${RISCV_DIR}/stubs"

# Copy syscall stub (FD mapping + spawn_elf)
cp "${RVEMU_DIR}/src/syscall.c" "${RISCV_DIR}/stubs/syscall_stubs.c" 2>/dev/null || true

# Copy CPU header (syscall numbers)
cp "${RVEMU_DIR}/includes/cpu.h" "${RISCV_DIR}/stubs/fd_map.h" 2>/dev/null || true

# Copy memmap header (MMIO addresses)
cp "${RVEMU_DIR}/includes/memmap.h" "${RISCV_DIR}/stubs/memmap.h" 2>/dev/null || true

# Copy virtio header
cp "${RVEMU_DIR}/includes/virtio.h" "${RISCV_DIR}/stubs/virtio.h" 2>/dev/null || true

# Copy bus header
cp "${RVEMU_DIR}/includes/bus.h" "${RISCV_DIR}/stubs/bus.h" 2>/dev/null || true

# Copy uart header
cp "${RVEMU_DIR}/includes/uart.h" "${RISCV_DIR}/stubs/uart.h" 2>/dev/null || true

echo "Stubs copied to: ${RISCV_DIR}/stubs/"

# Build RISC-V initramfs
echo "Building RISC-V initramfs..."
mkdir -p "${RISCV_DIR}/build"
"${RISCV_DIR}/scripts/build_riscv_initramfs.sh" "${RISCV_DIR}"

# Get RISC-V Linux image from RVLV buildroot
RV_KERNEL="${RVEMU_DIR}/buildroot/output/images/Image"
RV_ROOTFS="${RVEMU_DIR}/buildroot/output/images/rootfs.ext2"

if [ ! -f "$RV_KERNEL" ]; then
    echo "ERROR: RISC-V Linux kernel not found at ${RV_KERNEL}"
    echo "Build it with: cd ${RVEMU_DIR} && ./build_buildroot.sh"
    exit 1
fi

# Run on rvemu
echo ""
echo "Running TEAR-IX RISC-V on rvemu..."
echo "Kernel: ${RV_KERNEL}"
echo ""
"${RVEMU_BIN}" --linux \
    -k "${RV_KERNEL}" \
    -f "${RV_ROOTFS}" \
    --bootargs "console=ttyS0,115200n8 earlycon root=/dev/vda rw rootwait init=/sbin/tear-ix-init" \
    --max-inst 500000000
