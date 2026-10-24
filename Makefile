#!/usr/bin/env make
# TEAR-IX Makefile - top-level build orchestration
# Version: TEAR-IX.00.00
#
# Variants:
#   VARIANT=headless  (default) - Terminal-only, BusyBox init
#   VARIANT=gui       - XFCE desktop with fantasy theming
#   VARIANT=riscv     - RISC-V port using rvemu stubs

VARIANT ?= headless
export TEAR_IX_VARIANT := $(VARIANT)

.PHONY: all iso riscv clean test help iso-headless iso-gui

# Default: build ISO + RISC-V
all: iso riscv

# Build the ISO (dispatches to variant)
iso:
	@case "$(VARIANT)" in \
		gui)    echo "Building TEAR-IX GUI variant (XFCE)..." ;; \
		headless) echo "Building TEAR-IX headless/server variant..." ;; \
		riscv)  echo "Building TEAR-IX RISC-V port..." ;; \
		*)      echo "Unknown VARIANT: $(VARIANT) (use: headless, gui, riscv)"; exit 1 ;; \
	esac
	@cd iso && ./scripts/build_iso.sh "$(VARIANT)"

iso-headless:
	@cd iso && ./scripts/build_iso.sh headless

iso-gui:
	@cd iso && ./scripts/build_iso.sh gui

# Build/run the RISC-V port using rvemu stubs
riscv:
	@cd riscv && ./scripts/build_riscv.sh

# Clean all build artifacts
clean:
	@rm -rf iso/build/ iso/binary/ iso/live/ iso/chroot/ \
		riscv/build/ riscv/output/ riscv/stubs/
	@echo "Cleaned build artifacts"

# Run validation tests
test:
	@./iso/scripts/test_iso.sh
	@./riscv/scripts/test_riscv.sh

# Help
help:
	@echo "TEAR-IX.00.00 - Custom Ubuntu 22.04 Jammy Jelly remix"
	@echo ""
	@echo "Variants:"
	@echo "  headless  (default) Terminal-only, BusyBox init, server"
	@echo "  gui       XFCE desktop with RPG fantasy theming"
	@echo "  riscv     RISC-V port using rvemu stubs"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Build ISO + RISC-V port"
	@echo "  iso          - Build ISO (use VARIANT=<variant>)"
	@echo "  iso-headless - Build headless ISO"
	@echo "  iso-gui      - Build GUI ISO"
	@echo "  riscv        - Build/run RISC-V port on rvemu"
	@echo "  clean        - Remove build artifacts"
	@echo "  test         - Run validation tests"
	@echo "  help         - Show this help"
