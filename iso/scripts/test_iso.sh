#!/bin/bash
ISO_FILE="${1:-build/tear-ix.iso}"
QEMU_MEM="${2:-1G}"
TIMEOUT="${3:-30}"

timeout "$TIMEOUT" qemu-system-x86_64 \
    -bios /usr/share/ovmf/OVMF.fd \
    -cdrom "$ISO_FILE" \
    -m "$QEMU_MEM" \
    -serial stdio \
    -display none \
    -nographic \
    -no-reboot 2>&1
