#!/usr/bin/env python3
"""Build a FAT16 ESP image containing EFI/BOOT/BOOTX64.EFI"""
import struct, os, subprocess, sys

def build_esp(efi_file, esp_img, image_mb=16):
    with open(efi_file, 'rb') as f:
        efi_data = f.read()

    # Create image and format
    subprocess.run(["dd", "if=/dev/zero", f"of={esp_img}", "bs=1M", f"count={image_mb}"], capture_output=True)
    subprocess.run(["mkfs.fat", "-F", "16", "-n", "TEARIXESP", esp_img], capture_output=True)

    with open(esp_img, 'rb') as f:
        img = bytearray(f.read())

    # Parse BPB
    bps = struct.unpack_from('<H', img, 11)[0]
    spc = img[13]
    rsv = struct.unpack_from('<H', img, 14)[0]
    nfats = img[16]
    root_entries = struct.unpack_from('<H', img, 17)[0]
    spf = struct.unpack_from('<H', img, 22)[0]
    media = img[21]
    total_sec16 = struct.unpack_from('<H', img, 19)[0]
    total_sec32 = struct.unpack_from('<I', img, 32)[0]
    total_sectors = total_sec32 if total_sec16 == 0 else total_sec16

    fat_off = rsv * bps
    fat_size = spf * bps
    root_off = fat_off + nfats * fat_size
    root_size = root_entries * 32
    data_off = root_off + root_size
    cl_size = spc * bps
    total_clusters = (total_sectors * bps - data_off) // cl_size

    efi_clusters = max(1, (len(efi_data) + cl_size - 1) // cl_size)

    efi_dir_cluster = 2
    boot_dir_cluster = 3
    efi_file_first_cluster = 4

    if 4 + efi_clusters > total_clusters:
        print(f"ERROR: Not enough space ({4+efi_clusters} > {total_clusters})")
        sys.exit(1)

    # Update FAT
    fat = bytearray(img[fat_off:fat_off + fat_size])
    struct.pack_into('<H', fat, 0, 0xFF00 | media)
    struct.pack_into('<H', fat, 2, 0xFFFF)
    for i in range(efi_clusters):
        c = efi_file_first_cluster + i
        next_val = c + 1 if i + 1 < efi_clusters else 0xFFFF
        struct.pack_into('<H', fat, c * 2, next_val)
    struct.pack_into('<H', fat, efi_dir_cluster * 2, 0xFFFF)
    struct.pack_into('<H', fat, boot_dir_cluster * 2, 0xFFFF)
    for i in range(nfats):
        img[fat_off + i * fat_size : fat_off + (i+1) * fat_size] = fat

    # Directory entries
    def make_entry(name, fsize=0, fcluster=0, is_dir=False):
        e = bytearray(32)
        n = name.encode('ascii') if isinstance(name, str) else name
        if n == b'.': e[0:11] = b'.' + b' ' * 10
        elif n == b'..': e[0:11] = b'..' + b' ' * 9
        else:
            base, ext = (n.rsplit(b'.', 1) if b'.' in n else (n, b''))
            e[0:8] = base.ljust(8, b' ')[:8]
            e[8:11] = ext.ljust(3, b' ')[:3]
        e[11] = 0x10 if is_dir else 0x20
        struct.pack_into('<H', e, 14, 0x0000)
        struct.pack_into('<H', e, 16, 0x0021)
        struct.pack_into('<H', e, 18, 0x0021)
        struct.pack_into('<H', e, 22, 0x0000)
        struct.pack_into('<H', e, 24, 0x0021)
        struct.pack_into('<H', e, 26, fcluster)
        struct.pack_into('<I', e, 28, fsize)
        return e

    # EFI dir (cluster 2)
    efi_dir_off = data_off + (2 - 2) * cl_size
    efi_dir = bytearray(cl_size)
    efi_dir[0:32] = make_entry(".", 0, 2, True)
    efi_dir[32:64] = make_entry("..", 0, 0, True)
    efi_dir[64:96] = make_entry("BOOT", 0, 3, True)
    img[efi_dir_off:efi_dir_off + cl_size] = efi_dir

    # BOOT dir (cluster 3)
    boot_dir_off = data_off + (3 - 2) * cl_size
    boot_dir = bytearray(cl_size)
    boot_dir[0:32] = make_entry(".", 0, 3, True)
    boot_dir[32:64] = make_entry("..", 0, 2, True)
    boot_dir[64:96] = make_entry("BOOTX64.EFI", len(efi_data), 4, False)
    img[boot_dir_off:boot_dir_off + cl_size] = boot_dir

    # EFI file data
    efi_off = data_off + (4 - 2) * cl_size
    img[efi_off:efi_off + len(efi_data)] = efi_data

    # Root directory
    root = bytearray(root_size)
    root[0:11] = b'TEARIXESP '.ljust(11, b' ')
    root[11] = 0x28  # Volume label
    struct.pack_into('<H', root, 16, 0x0021)
    root[32:64] = make_entry("EFI", 0, 2, True)
    img[root_off:root_off + root_size] = root

    img[46:57] = b'TEARIXESP '.ljust(11, b' ')

    with open(esp_img, 'wb') as f:
        f.write(bytes(img))
    print(f"ESP written: {len(img)} bytes, {len(efi_data)} bytes of EFI data")

if __name__ == '__main__':
    build_esp(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else '/tmp/tear-ix_esp.img')
