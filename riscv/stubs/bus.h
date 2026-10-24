#ifndef BUS_H
#define BUS_H

#include "dram.h"
#include "uart.h"
#include "clint.h"
#include "plic.h"
#include "virtio.h"
#include "fpga_hw.h"

#define FPGA_MMIO_BASE  0x40000000ULL
#define FPGA_MMIO_SIZE  0x10000000ULL

typedef struct BUS {
    DRAM dram;
    UART uart;
    CLINT clint;
    PLIC plic;
    VIRTIO virtio;
    fpga_t fpga;
    fpga_bitstream_t fpga_bs;
    int fpga_loaded;
    int test_exit;
    int test_code;
} BUS;

int bus_init(BUS *bus, uint64_t dram_size, const char *disk_path, int virtio_legacy);
void bus_free(BUS *bus);
Trap bus_load(BUS *bus, uint64_t addr, uint64_t bits, uint64_t *out);
Trap bus_store(BUS *bus, uint64_t addr, uint64_t bits, uint64_t value);

#endif
