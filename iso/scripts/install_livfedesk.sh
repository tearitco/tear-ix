#!/bin/bash
# install_livfedesk.sh - Download and build the livedesk desktop environment
# This is TEAR-IX's "livfedesk installer" — fetches tearit-hq desktop components
# and compiles them in place. Named "livfedesk" (live-fed-desk) because TEAR-IX
# ships minimal but this feeds in the full desktop experience.
#
# Usage:
#   ./install_livfedesk.sh           # interactive (prompts, shows progress)
#   ./install_livfedesk.sh --silent  # silent install for autorun
#   ./install_livfedesk.sh --dry-run # show what would be downloaded without doing it
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEARIX_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
HQ_REPO="https://github.com/tearitco/TEARIT-HQ.git"
HQ_BRANCH="${HQ_BRANCH:-opencode}"
DESK_DIR="$HOME/.tearix/livedesk"

SILENT=0
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --silent|silent) SILENT=1 ;;
        --dry-run|dry-run) DRY_RUN=1 ;;
        *) echo "Unknown option: $arg"; echo "Usage: $0 [--silent] [--dry-run]"; exit 1 ;;
    esac
done

log() {
    if [ "$SILENT" = "0" ]; then
        echo -e "${GOLD}[$(date +%H:%M:%S)]${NC} $*"
    fi
}

GOLD='\033[0;33m'
CRIMSON='\033[0;31m'
TAN='\033[0;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Check prerequisites
check_prereqs() {
    local missing=""
    command -v git >/dev/null 2>&1 || missing="$missing git"
    command -v gcc >/dev/null 2>&1 || missing="$missing gcc"
    command -v pkg-config >/dev/null 2>&1 || missing="$missing pkg-config"
    pkg-config --exists x11 2>/dev/null || missing="$missing libx11-dev"
    pkg-config --exists xext 2>/dev/null || missing="$missing libxext-dev"
    pkg-config --exists xft 2>/dev/null || missing="$missing libxft-dev"

    if [ -n "$missing" ]; then
        echo -e "${CRIMSON}ERROR: Missing dependencies:${NC}$missing"
        echo "Debian/Ubuntu: sudo apt install git build-essential pkg-config libx11-dev libxext-dev libxft-dev"
        exit 1
    fi
}

# Download or update the tearit-hq desktop
fetch_desktop() {
    log "${PURPLE}=== Fetching TEARIT-HQ desktop from GitHub ==="
    log "${TAN}  Repo: ${HQ_REPO}"
    log "${TAN}  Branch: ${HQ_BRANCH}"
    log "${TAN}  Target: ${DESK_DIR}"

    if [ "$DRY_RUN" = "1" ]; then
        log "${GOLD}  [dry-run] Would clone ${HQ_REPO} (branch ${HQ_BRANCH}) to ${DESK_DIR}"
        return 0
    fi

    if [ -d "$DESK_DIR/.git" ]; then
        log "${GOLD}  Pulling latest changes..."
        cd "$DESK_DIR"
        git pull origin "$HQ_BRANCH"
    else
        log "${GOLD}  Cloning repository..."
        mkdir -p "$DESK_DIR"
        git clone -b "$HQ_BRANCH" --depth 1 "$HQ_REPO" "$DESK_DIR"
    fi

    log "${PURPLE}Desktop fetched to: ${DESK_DIR}"
}

# Build the desktop components
build_desktop() {
    log "${PURPLE}=== Building livedesk components ==="

    if [ "$DRY_RUN" = "1" ]; then
        log "${GOLD}  [dry-run] Would run bootstrap.sh in ${DESK_DIR}/xyz-installer-dev/payload-src/"
        return 0
    fi

    local PAYLOAD_DIR="$DESK_DIR/xyz-installer-dev/payload-src"
    if [ ! -f "$PAYLOAD_DIR/bootstrap.sh" ]; then
        echo -e "${CRIMSON}ERROR: bootstrap.sh not found at ${PAYLOAD_DIR}"
        echo "Expected directory structure from TEARIT-HQ repository."
        exit 1
    fi

    log "${GOLD}  Running bootstrap.sh..."
    ( cd "$PAYLOAD_DIR" && sh ./bootstrap.sh )

    log "${PURPLE}Build complete."
}

# Create a launcher on the TEAR-IX desktop
create_launcher() {
    log "${PURPLE}=== Creating desktop integration ==="

    local DESKTOP_DIR="$HOME/Desktop"
    local LAUNCHER="$DESKTOP_DIR/tear-ix-livedesk.desktop"

    if [ "$DRY_RUN" = "1" ]; then
        log "${GOLD}  [dry-run] Would create launcher at ${LAUNCHER}"
        return 0
    fi

    # Also install to autostart for auto-launch on first boot
    local AUTOSTART_DIR="$HOME/.config/autostart"
    mkdir -p "$DESKTOP_DIR" "$AUTOSTART_DIR"

    # Desktop launcher (GUI)
    cat > "$LAUNCHER" << 'LAUNCHER_EOF'
[Desktop Entry]
Type=Application
Name=TEAR-IX Livedesk
Comment=Start the livedesk desktop environment
Exec=sh -c 'cd ~/.tearix/livedesk/xyz-installer-dev/payload-src && sh start.sh'
Icon=applications-system
Terminal=false
Categories=System;Desktop;
StartupNotify=true
LAUNCHER_EOF
    chmod +x "$LAUNCHER"

    # Headless autorun script (for terminal sessions)
    local HEADLESS_AUTORUN="$HOME/.tearix/autorun_livedesk.sh"
    cat > "$HEADLESS_AUTORUN" << 'AUTORUN_EOF'
#!/bin/bash
# TEAR-IX autorun: launch livedesk if available
if [ -x "$HOME/.tearix/livedesk/xyz-installer-dev/payload-src/start.sh" ]; then
    exec "$HOME/.tearix/livedesk/xyz-installer-dev/payload-src/start.sh"
fi
exit 0
AUTORUN_EOF
    chmod +x "$HEADLESS_AUTORUN"

    log "${PURPLE}Desktop launcher: ${LAUNCHER}"
    log "${PURPLE}Headless autorun: ${HEADLESS_AUTORUN}"
}

# Main
main() {
    echo -e "${PURPLE}  ============================================================"
    echo -e "${PURPLE}  |                                                          |"
    echo -e "${GOLD}  |     TEAR-IX LIVFEDESK INSTALLER                          |"
    echo -e "${PURPLE}  |                                                          |"
    echo -e "${CRIMSON}  |      tear-ix ; by tear-it co                             |"
    echo -e "${PURPLE}  |                                                          |"
    echo -e "${GOLD}  |     Version 00.00  |  Jammy Jellyfish                    |"
    echo -e "${PURPLE}  |                                                          |"
    echo -e "${TAN}  |     Fetching + building livedesk from TEARIT-HQ            |"
    echo -e "${PURPLE}  |                                                          |"
    echo -e "${PURPLE}  ============================================================"
    echo ""

    check_prereqs
    fetch_desktop
    build_desktop
    create_launcher

    echo ""
    echo -e "${CRIMSON}  Boot complete. Welcome to TEAR-IX with livedesk.${NC}"
    echo ""
    if [ "$SILENT" = "0" ]; then
        echo "  Next steps:"
        echo "    - GUI: Click the 'TEAR-IX Livedesk' icon on your Desktop"
        echo "    - Headless: Run '~/.tearix/autorun_livedesk.sh'"
        echo "    - Or: cd ~/.tearix/livedesk/xyz-installer-dev/payload-src && sh start.sh"
    fi
}

main "$@"
