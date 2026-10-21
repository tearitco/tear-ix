#!/usr/bin/env make
# TEAR-IX Makefile - top-level build orchestration
# Version: TEAR-IX.00.00

.PHONY: all iso riscv clean test help

# Default: build everything
all: iso riscv

# Build the x86_64 UEFI ISO
iso:
	@cd iso && \
	./scripts/build_iso.sh

# Build/run the RISC-V port using rvemu stubs
riscv:
	@cd riscv && \
	./scripts/build_riscv.sh

# Clean all build artifacts
clean:
	@rm -rf iso/build/ iso/binary/ iso/live/ riscv/build/ riscv/output/
	@echo "Cleaned build artifacts"

# Run validation tests
test:
	@./iso/scripts/test_iso.sh
	@./riscv/scripts/test_riscv.sh

# Help
help:
	@echo "TEAR-IX.00.00 - Custom Ubuntu ISO"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build both ISO and RISC-V port"
	@echo "  iso      - Build x86_64 UEFI ISO"
	@echo "  riscv    - Build/run RISC-V port on rvemu"
	@echo "  clean    - Remove build artifacts"
	@echo "  test     - Run validation tests"
	@echo "  help     - Show this help"
