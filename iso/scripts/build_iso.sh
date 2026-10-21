#!/usr/bin/env bash
# build_iso.sh - Build the TEAR-IX x86_64 UEFI ISO using live-build
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ISO_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$ISO_DIR")"

echo "=== TEAR-IX.00.00 ISO Build ==="
echo "Project root: ${PROJECT_ROOT}"
echo ""

# Check for live-build
if ! command -v lb &>/dev/null; then
    echo "ERROR: live-build (lb) is not installed."
    echo "Install: sudo apt-get install -y live-build"
    exit 1
fi

# Check for required tools
for tool in grub-efi-amd64-bin grub-pc-bin xorriso squashfs-tools mksquashfs; do
    if ! command -v "$tool" &>/dev/null 2>&1; then
        echo "WARNING: ${tool} not found. Build may fail."
    fi
done

# Clean previous build
echo "Cleaning previous build..."
sudo rm -rf "${ISO_DIR}/binary" "${ISO_DIR}/chroot" "${ISO_DIR}/.build"
rm -rf "${ISO_DIR}/build"
mkdir -p "${ISO_DIR}/build"

# Run lb config
echo "Configuring live-build..."
cd "${ISO_DIR}"
sudo lb config \
    --distribution jammy \
    --architecture amd64 \
    --binary-images iso-hybrid \
    --bootloader grub \
    --memtest none \
    --debian-installer false \
    --security true \
    --updates true \
    --backports true \
    --archive-areas "main restricted universe multiverse" \
    --linux-flavour generic \
    --linux-packages "linux-image-generic"

# Copy package lists
echo "Copying package lists..."
cp "${ISO_DIR}/package-lists/"*.list* "${ISO_DIR}/config/" 2>/dev/null || true
cp "${ISO_DIR}/package-lists/"*.packages "${ISO_DIR}/config/" 2>/dev/null || true

# Run hooks (they are in iso/hooks/)
# live-build expects hooks in config/hooks/ as numbered scripts
echo "Setting up hooks..."
for hook in "${ISO_DIR}/hooks/"*.chroot; do
    [ -f "$hook" ] && cp "$hook" "${ISO_DIR}/config/hooks/" 2>/dev/null || true
done

# Copy overlays
echo "Setting up filesystem overlays..."
if [ -d "${ISO_DIR}/overlays" ]; then
    cp -r "${ISO_DIR}/overlays/etc/"* "${ISO_DIR}/config/includes.chroot/etc/" 2>/dev/null || true
    cp -r "${ISO_DIR}/overlays/usr/"* "${ISO_DIR}/config/includes.chroot/usr/" 2>/dev/null || true
    cp -r "${ISO_DIR}/overlays/var/"* "${ISO_DIR}/config/includes.chroot/var/" 2>/dev/null || true
fi

# Install branding
echo "Installing branding assets..."
"${ISO_DIR}/scripts/install_branding.sh" "${ISO_DIR}"

# Build
echo ""
echo "Building ISO (this may take 10-30 minutes)..."
sudo lb build

# Move output
if [ -f "${ISO_DIR}/tearix_jammy-amd64.iso" ]; then
    mv "${ISO_DIR}/tearix_jammy-amd64.iso" "${ISO_DIR}/build/tear-ix_jammy-amd64.iso"
    echo ""
    echo "=== ISO built successfully ==="
    echo "Output: ${ISO_DIR}/build/tear-ix_jammy-amd64.iso"
    ls -lh "${ISO_DIR}/build/tear-ix_jammy-amd64.iso"
elif [ -f "binary.iso" ]; then
    mv binary.iso "${ISO_DIR}/build/tear-ix_jammy-amd64.iso"
    echo ""
    echo "=== ISO built successfully ==="
    echo "Output: ${ISO_DIR}/build/tear-ix_jammy-amd64.iso"
    ls -lh "${ISO_DIR}/build/tear-ix_jammy-amd64.iso"
else
    echo "ERROR: ISO not found after build"
    echo "Checking for any .iso files..."
    find . -name "*.iso" -type f 2>/dev/null
    exit 1
fi
