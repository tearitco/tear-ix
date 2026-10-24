#ifndef VIRTIO_H
#define VIRTIO_H

#include <stdint.h>
#include "trap.h"

typedef struct DRAM DRAM;

typedef struct VIRTIO {
    uint8_t *disk;
    uint64_t disk_size;
    int legacy;
    uint32_t status;
    uint32_t device_features_sel;
    uint32_t driver_features_sel;
    uint32_t driver_features;
    uint32_t guest_page_size;
    uint32_t queue_sel;
    uint32_t queue_num;
    uint32_t queue_pfn;
    uint32_t queue_ready;
    uint64_t queue_desc;
    uint64_t queue_driver;
    uint64_t queue_device;
    uint32_t interrupt_status;
    uint16_t last_avail_idx;
    uint16_t used_idx;
    int notify;
    int present;
} VIRTIO;

int virtio_init(VIRTIO *v, const char *disk_path, int legacy);
void virtio_free(VIRTIO *v);
int virtio_irq_pending(VIRTIO *v);
void virtio_disk_access(VIRTIO *v, DRAM *dram);
Trap virtio_load(VIRTIO *v, uint64_t addr, uint64_t bits, uint64_t *out);
Trap virtio_store(VIRTIO *v, uint64_t addr, uint64_t bits, uint64_t value);

#endif
