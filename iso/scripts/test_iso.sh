#!/usr/bin/env bash
# test_iso.sh - Validate the TEAR-IX ISO structure and contents
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="$(dirname "$SCRIPT_DIR")"
ISO_FILE="${ISO_DIR}/build/tear-ix_jammy-amd64.iso"

ERRORS=0

echo "=== TEAR-IX ISO Validation ==="
echo ""

# Test 1: ISO exists
echo -n "Test 1: ISO exists... "
if [ -f "$ISO_FILE" ]; then
    echo "PASS"
else
    echo "FAIL (file not found: $ISO_FILE)"
    ERRORS=$((ERRORS + 1))
fi

# Test 2: ISO has valid filesystem structure
echo -n "Test 2: ISO filesystem structure... "
if [ -f "$ISO_FILE" ]; then
    if file "$ISO_FILE" | grep -qi "ISO 9660"; then
        echo "PASS"
    else
        echo "FAIL (not a valid ISO 9660 image)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP (no ISO file)"
fi

# Test 3: Branding present
echo -n "Test 3: TEAR-IX branding present... "
if [ -f "$ISO_FILE" ]; then
    if xorriso -indev "$ISO_FILE" -find / 2>/dev/null | grep -qi "tear-ix\|tear-it co" 2>/dev/null; then
        echo "PASS"
    else
        echo "FAIL (no TEAR-IX branding found in ISO)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP (no ISO file)"
fi

# Test 4: UEFI bootable
echo -n "Test 4: UEFI boot support... "
if [ -f "$ISO_FILE" ]; then
    if xorriso -indev "$ISO_FILE" -find / 2>/dev/null | grep -qi "efi" 2>/dev/null; then
        echo "PASS"
    else
        echo "FAIL (no EFI partition found)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP (no ISO file)"
fi

# Test 5: BusyBox present
echo -n "Test 5: BusyBox init... "
if [ -f "$ISO_FILE" ]; then
    if xorriso -indev "$ISO_FILE" -find / 2>/dev/null | grep -qi "busybox" 2>/dev/null; then
        echo "PASS"
    else
        echo "FAIL (busybox not found)"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "SKIP (no ISO file)"
fi

# Test 6: No Ubuntu branding
echo -n "Test 6: No Ubuntu branding... "
if [ -f "$ISO_FILE" ]; then
    if xorriso -indev "$ISO_FILE" -find / 2>/dev/null | grep -qi "ubuntu" 2>/dev/null; then
        echo "WARN (Ubuntu strings still present in ISO)"
    else
        echo "PASS"
    fi
else
    echo "SKIP (no ISO file)"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
    echo "=== All tests passed ==="
    exit 0
else
    echo "=== $ERRORS test(s) failed ==="
    exit 1
fi
