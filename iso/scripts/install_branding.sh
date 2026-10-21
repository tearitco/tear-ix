#!/usr/bin/env bash
# install_branding.sh - Copy TEAR-IX branding assets into the ISO chroot
set -euo pipefail

ISO_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
BRANDING_SRC="${ISO_DIR}/../branding"
CHROOT_DIR="${ISO_DIR}/config/includes.chroot"

echo "Installing TEAR-IX branding..."

# Ensure target directories exist
mkdir -p "${CHROOT_DIR}/usr/share/backgrounds/tear-ix"
mkdir -p "${CHROOT_DIR}/usr/share/pixmaps/tear-ix"
mkdir -p "${CHROOT_DIR}/usr/share/icons/hicolor/scalable/apps"
mkdir -p "${CHROOT_DIR}/boot/grub"
mkdir -p "${CHROOT_DIR}/etc/plymouth"
mkdir -p "${CHROOT_DIR}/usr/lib/grub/grub-mkstandalone"

# Copy logos
for logo in tear-ix-logo.svg tear-ix-logo.png tear-ix-logo-64.png; do
    if [ -f "${BRANDING_SRC}/logos/${logo}" ]; then
        cp "${BRANDING_SRC}/logos/${logo}" "${CHROOT_DIR}/usr/share/pixmaps/tear-ix/${logo}"
    fi
done

# Copy wallpapers
if [ -d "${BRANDING_SRC}/logos/wallpapers" ]; then
    cp -r "${BRANDING_SRC}/logos/wallpapers/"* "${CHROOT_DIR}/usr/share/backgrounds/tear-ix/" 2>/dev/null || true
fi

# Copy fonts (fantasy fonts for branding)
if [ -d "${BRANDING_SRC}/assets/fonts" ]; then
    mkdir -p "${CHROOT_DIR}/usr/share/fonts/truetype/tear-ix"
    cp -r "${BRANDING_SRC}/assets/fonts/"* "${CHROOT_DIR}/usr/share/fonts/truetype/tear-ix/" 2>/dev/null || true
fi

# Generate GRUB theme from template
cat > "${CHROOT_DIR}/boot/grub/theme.txt" << 'THEME'
# TEAR-IX GRUB Theme - "tear-ix ; by tear-it co"
# Colors: #FFCC00 (gold), #DC143C (crimson), #D2B48C (tan), #9370DB (purple)
desktop-image -m "0,0" "parchment_tan"
terminal-box -s 0 0 -e 0 -t 0 -x 0 -y 0 -w 80 -h 24 -c "tan" -b "purple"
set color_normal="crimson/tan"
set menu_color_normal="crimson/tan"
set menu_color_highlight="gold/purple"
THEME

# Generate plymouth config (boot splash)
mkdir -p "${CHROOT_DIR}/usr/share/plymouth/themes/tear-ix"
cat > "${CHROOT_DIR}/usr/share/plymouth/themes/tear-ix/tear-ix.plymouth" << 'PLYMOUTH'
[Plymouth Theme]
Name=TEAR-IX
Description=RPG Fantasy Boot Splash
ModuleName=script

[script]
TEAR-IX ; by tear-it co
PLYMOUTH

# Replace default GRUB background
cat > "${CHROOT_DIR}/boot/grub/tearix.cfg" << 'GRUBCFG'
set default="0"
set timeout="10"
set color_normal="crimson/tan"
set menu_color_normal="crimson/tan"
set menu_color_highlight="gold/purple"
set gfxmode=auto
insmod jpeg
insmod png
if loadfont /boot/grub/fonts/unicode.pf2; then
    set gfxmode=auto
    insmod gfxterm
    terminal gfxterm
fi
GRUBCFG

echo "Branding installed to: ${CHROOT_DIR}"
