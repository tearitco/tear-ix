#!/bin/bash
# tear-ix-logo.sh - Render the TEAR-IX logo with color
# Colors: Gold, Crimson, Tan, Purple

# ANSI color codes
GOLD='\033[0;33m'      # #FFCC00 - Yellow/Gold
CRIMSON='\033[0;31m'   # #DC143C - Red/Crimson
TAN='\033[0;37m'       # #D2B48C - Tan (using white as approximation)
PURPLE='\033[0;35m'    # #9370DB - Purple
BOLD='\033[1m'
NC='\033[0m'           # No Color

echo ""
echo -e "${PURPLE}  ╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}  ║                                                              ║${NC}"
echo -e "${GOLD}  ║     🛡️  TEAR-IX${GOLD}                                          ║${NC}"
echo -e "${PURPLE}  ║                                                              ║${NC}"
echo -e "${CRIMSON}  ║      tear-ix ; by tear-it co${CRIMSON}                                ║${NC}"
echo -e "${PURPLE}  ║                                                              ║${NC}"
echo -e "${GOLD}  ║     Version ${BOLD}00.00${NC}${GOLD}  |  ${BOLD}Jammy Jellyfish${GOLD}                        ║${NC}"
echo -e "${PURPLE}  ║                                                              ║${NC}"
echo -e "${TAN}  ║     A lite Ubuntu 22.04 remix with RPG fantasy theming       ║${NC}"
echo -e "${PURPLE}  ║                                                              ║${NC}"
echo -e "${PURPLE}  ╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
