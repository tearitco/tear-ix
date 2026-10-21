#!/usr/bin/env bash
# test_riscv.sh - Validate TEAR-IX RISC-V port
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RISCV_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== TEAR-IX RISC-V Validation ==="

ERRORS=0

# Test 1: Stubs present
echo -n "Test 1: rvemu stubs present... "
if [ -f "${RISCV_DIR}/stubs/syscall_stubs.c" ] && \
   [ -f "${RISCV_DIR}/stubs/fd_map.h" ] && \
   [ -f "${RISCV_DIR}/stubs/memmap.h" ]; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

# Test 2: Init script exists
echo -n "Test 2: Init script exists... "
if [ -f "${RISCV_DIR}/build/initramfs/sbin/tear-ix-init" ]; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

# Test 3: rvemu binary exists
echo -n "Test 3: rvemu binary... "
if [ -f "${RISCV_DIR}/../1.RVEM/RVLV_EMUL/build/main" ]; then
    echo "PASS"
else
    echo "FAIL (build rvemu first)"
    ERRORS=$((ERRORS + 1))
fi

# Test 4: Branding reference
echo -n "Test 4: Branding reference valid... "
if grep -q "tear-it co" "${RISCV_DIR}/build/initramfs/sbin/tear-ix-init" 2>/dev/null; then
    echo "PASS"
else
    echo "FAIL"
    ERRORS=$((ERRORS + 1))
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "=== All RISC-V tests passed ==="
    exit 0
else
    echo "=== $ERRORS test(s) failed ==="
    exit 1
fi
