# TEAR-IX ISO Build Guide

## Overview

The ISO is built using `live-build` (Debian/Ubuntu's official live image build tool).
It produces a hybrid ISO that is UEFI-bootable on x86_64.

## Prerequisites

```bash
sudo apt-get install -y live-build grub-efi-amd64-bin grub-pc-bin \
    xorriso squashfs-tools rsync
```

## Build Steps

### 1. Configure the build

```bash
cd iso/
lb config \
    --distribution jammy \
    --architecture amd64 \
    --binary-images iso-hybrid \
    --bootloader grub \
    --archive-areas "main restricted universe multiverse" \
    --security true \
    --debian-installer false \
    --memtest none \
    --archive-areas "main restricted universe multiverse"
```

### 2. Run the build

```bash
make iso        # from project root
# or:
cd iso && sudo lb build
```

### 3. Output

The ISO is produced at `iso/build/tear-ix_jammy-amd64.iso`.

## Build Configuration

| Setting | Value | Notes |
|---------|-------|-------|
| Distribution | jammy (Ubuntu 22.04) | Pinned to Jammy Jellyfish |
| Architecture | amd64 | x86_64 target |
| Bootloader | grub-efi | UEFI + legacy BIOS hybrid |
| Init system | BusyBox | systemd replaced |
| Package list | `iso/config/packages.list` | Minimal set |

## Package Selection

Core packages (in `iso/config/packages.list`):

```
busybox-init
busybox-static
vim-tiny
nano
curl
wget
openssh-client
ca-certificates
udev
dhcpcd5
```

All Ubuntu branding packages are excluded:
```
- ubuntu-desktop
- ubuntu-session
- gdm3
- gnome-shell
```

## Customization Hooks

Live-build hooks in `iso/hooks/` run during the build:

| Hook | Purpose |
|------|---------|
| `0001-branding.chroot` | Install TEAR-IX branding files |
| `0002-busybox-init.chroot` | Configure BusyBox as init |
| `0003-grub.chroot` | Install custom GRUB theme |
| `0004-cleanup.chroot` | Remove unnecessary files, shrink image |

## Overlay Files

Filesystem overlays live in `iso/overlays/`:

```
overlays/
├── etc/           # Custom /etc (inittab, fstab, hosts, hostname)
├── usr/           # Custom /usr (logo, theme files)
└── var/           # Custom /var (log dirs, etc.)
```

## Boot Parameters

The GRUB configuration uses these boot args (mirroring RVLV's approach):

```
console=ttyS0 console=tty0
earlycon
root=/dev/sr0
ro
init=/sbin/init    (BusyBox init)
```

## Testing the ISO

```bash
# Verify ISO structure
./iso/scripts/test_iso.sh

# Boot in QEMU (UEFI)
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd \
    -cdrom iso/build/tear-ix_jammy-amd64.iso \
    -m 2G

# Boot in QEMU (legacy BIOS)
qemu-system-x86_64 -cdrom iso/build/tear-ix_jammy-amd64.iso -m 2G
```
