# TEAR-IX Branding Guide

## Color Palette

**Primary colors** (use ONLY these — no other colors in branding):

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Fairy Gold | `#FFCC00` | 255,204,0 | Primary accent, highlights, logo sunburst |
| Potion Crimson | `#DC143C` | 220,20,60 | Danger/alert, installer highlights, health potions |
| Parchment Tan | `#D2B48C` | 210,180,140 | Backgrounds, parchment UI, text areas |
| Arcane Purple | `#9370DB` | 147,112,219 | Magic/seals, logo, mystical elements |

## Logo Concept

```
        ╔══════════════════╗
        ║    🛡️ TEAR-IX    ║
        ║  tear-ix         ║
        ║  ; by tear-it co ║
        ╚══════════════════╝
```

- **Shape**: Circular shield/seal (like a guild emblem)
- **Outer ring**: Arcane purple border with quill-feather texture
- **Center**: Stylized "TI" monogram in gold/yellow
- **Bottom banner**: Parchment tan ribbon with "tear-ix ; by tear-it co" in crimson
- **Sparkles**: Fairy-dust gold sparkles around the edges

## Visual Elements

### Icons (RPG-themed)
- **Shields/Seals**: Volume icons, file system icons
- **Potions**: Progress bar fill, battery indicator
- **Quills**: Text cursor, terminal prompt `>`, progress markers
- **Fairy dust sparkles**: Window decorations, hover effects, boot splash particles

### GRUB Menu
- Background: Parchment tan with faint parchment texture
- Menu entries in crimson, selected entry highlighted in gold
- Title: "tear-ix ; by tear-it co" in arcane purple
- Boot options styled as "quest choices"

### Boot Splash (Plymouth theme)
- Animated parchment scroll unfurling
- Fairy dust particles swirling around the TEAR-IX logo
- Progress bar styled as a potion filling up (crimson → gold gradient)

### Wallpaper
- 1920x1080 fantasy scene: ancient library with books, scrolls, potions, and a
  magical shield bearing the TEAR-IX monogram
- Color palette limited to the four brand colors

## Typography

- **Logo text**: Medieval/fantasy font (e.g., "Cinzel" or "UnifrakturCook")
- **UI text**: Clean sans-serif (e.g., "DejaVu Sans" — default in Ubuntu)
- **Terminal**: Monospace (e.g., "DejaVu Sans Mono")

## Branding Files

All branding assets live in `branding/` with this structure:

```
branding/
├── logos/
│   ├── tear-ix-logo.svg       # Vector logo (shield/seal)
│   ├── tear-ix-logo.png       # 512x512 PNG
│   ├── tear-ix-logo-64.png    # 64x64 for GRUB
│   └── tear-ix-splash.png     # Full splash screen
├── themes/
│   ├── grub/                  # GRUB theme files
│   ├── plymouth/              # Boot splash theme
│   └── desktop/               # GTK/icons theme
└── assets/
    ├── fonts/                 # Fantasy fonts
    └── pixmaps/               # UI pixmaps (potions, quills, etc.)
```
