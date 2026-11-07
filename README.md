Duck-ai-image-2026-11-07-07-52.jpeg 💿
💧
# TEAR-IX - A Custom Ubuntu-Based ISO

**Version:** TEAR-IX.00.00  
**Codename:** "Jammy Jelly" (based on Ubuntu 22.04 LTS)  
**Tagline:** `tear-ix ; by tear-it co`  
**Theme:** RPG fantasy (shields, seals, potions, quills, fairy dust)  
**Color Scheme:** Yellow (#FFD700), Red (#DC143C), Tan (#D2B48C), Purple (#9370DB)

---

## What Is TEAR-IX?

TEAR-IX is a hand-crafted, lightweight Ubuntu 22.04 (Jammy) variant that replaces
the stock Ubuntu branding with an RPG fantasy theme. It is built using `live-build`
and ships with BusyBox as the init system, giving it a minimal "lite" footprint
while remaining installable via a standard ISO installer.

### Key Features

- **UEFI-ready** — boots on modern x86_64 hardware via GRUB EFI + fallback
- **BusyBox init** — replaces systemd with a lightweight init for minimal footprint
- **Custom branding** — logo, splash, GRUB menu, wallpapers, and UI all themed
  around RPG fantasy imagery
- **RISC-V port** — uses rvemu stubs to run the same base on RISC-V hardware
- **Install ISO** — hybrid ISO that works from USB/DVD, with installer support

### Directory Layout

```
TEAR-IX/
├── iso/                    # ISO build tree (live-build config)
│   ├── config/             # live-build configuration (auto/config)
│   ├── hooks/              # Build hooks (nightly customization scripts)
│   ├── overlays/           # Filesystem overlays (squashfs content)
│   ├── scripts/            # Post-install/build scripts
│   └── build/              # Output artifacts (gitignored)
├── riscv/                  # RISC-V port (borrows stubs from RVLV_EMUL)
│   ├── rvemu/              # Symlink or fork of rvemu for RISC-V boot
│   ├── stubs/              # Shared syscall/spawn_elf stubs
│   └── build/
├── bootloader/             # GRUB/EFISTUB bootloader config
├── branding/               # Logos, themes, wallpapers, splash
│   ├── logos/
│   ├── themes/
│   └── assets/
├── packages/               # Custom .deb packages (TEAR-IX branding, etc.)
├── docs/                   # Design docs, build guides, porting notes
├── Makefile                # Top-level build orchestration
└── AGENTS.md               # Agent workflow / constraints
```

### Quick Start (Build)

```bash
# Install live-build (Ubuntu/Debian)
sudo apt-get install live-build

# Build the ISO
make iso        # or: ./iso/scripts/build_iso.sh

# The ISO appears at:
#   iso/build/tear-ix_jammy-amd64.iso
```

### Quick Start (RISC-V)

```bash
make riscv      # Builds RISC-V variant using rvemu stubs
```

---

## Boot Proof (QEMU Verified)

The ISO has been verified to boot fully in QEMU with OVMF UEFI firmware. The full boot chain is:

1. **OVMF firmware** loads the El Torita EFI boot entry from the ISO
2. **GRUB EFI** binary (BOOTX64.EFI) executes, displaying the TEAR-IX branded menu
3. **GRUB** loads the kernel (`/live/vmlinuz`) and initramfs (`/live/initrd`)
4. **Kernel** boots with command line: `root=/dev/ram0 rw init=/init console=ttyS0,115200n8`
5. **Initramfs** unpacks as rootfs, kernel runs `/init`
6. **TEAR-IX branded welcome** message displays with RPG fantasy color scheme
7. **BusyBox shell** starts (ash, v1.30.1)

### Boot Variants

TEAR-IX ships three bootable variants, selectable from the GRUB menu:

| Variant | Description | Kernel cmdline |
|---------|-------------|----------------|
| **Server** (default) | Headless, BusyBox init, terminal-only | `root=/dev/ram0 rw init=/init console=ttyS0,115200n8` |
| **Desktop** | GUI, XFCE with RPG fantasy theming | `root=/dev/ram0 rw init=/init-gui console=ttyS0,115200n8` |
| **RISC-V** | RISC-V port using rvemu stubs | `root=/dev/ram0 rw init=/init console=ttyS0,115200n8` |

### QEMU Boot Test Command (No Graphics)

```bash
timeout 60 qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom ship/tear-ix_uefi.iso \
    -m 512M \
    -display none \
    -nographic \
    -no-reboot
```

### QEMU Test Command (With Graphics)

```bash
timeout 60 qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom ship/tear-ix_uefi.iso \
    -m 512M \
    -vga std \
    -display vnc=:1 \
    -serial file:/tmp/qemu_serial.log \
    -no-reboot
```

### Expected Console Output

```
GNU GRUB  version 2.06
...
*TEAR-IX Live - Boot (tear-ix ; by tear-it co)
...

[    0.000000] Linux version 5.15.0-198-generic ...
[    7.494009] Trying to unpack rootfs image as initramfs...
[   11.948013] Run /init as init process

  ============================================================
  |                                                          |
  |     TEAR-IX                                              |
  |                                                          |
  |      tear-ix ; by tear-it co                            |
  |                                                          |
  |     Version 00.00  |  Jammy Jellyfish                    |
  |                                                          |
  |     A lite Ubuntu 22.04 remix (RPG fantasy themed)       |
  |                                                          |
  ============================================================

  Boot complete. Welcome to TEAR-IX.
  root@tear-ix:~ 

BusyBox v1.30.1 (Ubuntu 1:1.30.1-7ubuntu3.1) built-in shell (ash)
Enter 'help' for a list of built-in commands.

sh: can't access tty; job control turned off
/ #
```

### Boot Verification Log

Full kernel boot log captured from QEMU run (60s timeout):
- Kernel version: 5.15.0-198-generic
- Initramfs unpacks successfully (2148K freed)
- `/init` script executes with TEAR-IX branding
- BusyBox shell starts at `/ #` prompt
- Console output confirms: `Run /init as init process` → branded banner → BusyBox shell

---

## USB Installation

The TEAR-IX ISO can be written directly to a USB drive using the included script. This replaces any existing content on the USB.

### Install to USB

**Requires root access (sudo).** Run from the TEAR-IX project directory:

```bash
# Find your USB device first
lsblk

# Write TEAR-IX to USB (replaces all data on the drive)
sudo ./iso/scripts/install-tear-ix-usb.sh /dev/sdb

# With verification
sudo ./iso/scripts/install-tear-ix-usb.sh /dev/sdb --verify
```

Or via Makefile:
```bash
make usb DEVICE=/dev/sdb
make usb DEVICE=/dev/sdb VERIFY=--verify
```

### Boot from USB

1. Insert the USB drive
2. Boot your machine and enter the firmware/UEFI boot menu (usually F12, Esc, or F2)
3. Select the USB drive as the boot device
4. The TEAR-IX GRUB menu will appear with options for:
   - **Server** (headless, BusyBox init) - default
   - **Desktop** (GUI, XFCE with RPG fantasy theming)
   - **RISC-V** (RISC-V port using rvemu stubs)

---

## Minimal Embedded Build

For embedded/CLI use, TEAR-IX can be built as a ~15MB bootable image (vs 38MB for the full ISO). Uses EFI stub kernel (no GRUB) + minimal BusyBox initramfs.

### Build

```bash
make minimal
# or:
./iso/scripts/build_minimal_embedded.sh
```

### Test

```bash
make minimal-test
# or:
./iso/scripts/test_minimal_embedded.sh
```

### Expected Output

The minimal image boots directly to a BusyBox shell with TEAR-IX branding. No GRUB menu, no packages — just kernel + BusyBox.

### Size Breakdown

| Component | Size |
|-----------|------|
| Kernel (EFI stub) | ~12MB |
| Initramfs (BusyBox) | ~2MB |
| ESP image (FAT16) | ~4MB |
| **Total** | **~15MB** |

### Boot Command

```bash
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd \
    -drive file=iso/build/minimal/tear-ix-minimal.img,format=raw \
    -m 512M -nographic
```

---

## Relationship to RVLV_EMUL

This project borrows heavily from the RVLV_EMUL project (`../1.RVEM/RVLV_EMUL/`).
Specifically:

- **rvemu stubs**: The RISC-V port reuses the syscall ABI, `spawn_elf` protocol,
  and VirtIO/MMIO infrastructure from rvemu as the "stub" interface layer.
- **prisc+x VM**: The `.pal` VM from RVLV_EMUL is referenced for any minimal
  runtime needs on RISC-V (where full Linux isn't feasible).
- **Bootstrap philosophy**: TEAR-IX does not depend on systemd; instead it uses
  BusyBox init, mirroring RVLV_EMUL's "minimal dependencies" philosophy.
- **HDLb0 / SFPGA**: The discrete FPGA emulator work is referenced for potential
  future hardware-level customization of the boot process.

See [docs/RVLV_LEARNINGS.md](docs/RVLV_LEARNINGS.md) for the full mapping of
RVLV concepts to TEAR-IX.

---

## Branding Concept

> "tear-ix ; by tear-it co"

The color palette is inspired by RPG visual elements:

| Color | Hex | Symbolic Meaning |
|-------|-----|-----------------|
| Gold/Yellow | `#FFCC00` | Fairy dust, sunlight, rare loot |
| Crimson Red | `#DC143C` | Health potions, battle, power |
| Tan/Brown | `#D2B48C` | Parchment, leather, aged wood |
| Royal Purple | `#9370DB` | Magic, arcane seals, mysticism |

Key visual elements:
- **Shield/seal motif** for the logo (circular badge design)
- **Potion bottles** in the installer UI
- **Quill pen** for text cursor and progress indicators
- **Fairy dust sparkles** for splash animation

---

## License

See [LICENSE](LICENSE) file. TEAR-IX branding is original work by tear-it co.
The underlying Ubuntu base retains its original license.
