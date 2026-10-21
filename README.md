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
