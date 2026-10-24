#!/usr/bin/env python3
"""Create a FAT16 disk image with proper ESP structure for UEFI boot.
Builds the entire FAT16 filesystem from scratch - no external tools needed.
"""
import struct
import sys

def make_fat16_esp(efi_binary_path, output_path, image_size_mb=64):
    with open(efi_binary_path, 'rb') as f:
        efi_data = f.read()

    IMAGE_SIZE = image_size_mb * 1024 * 1024
    BYTES_PER_SECTOR = 512
    SECTORS_PER_CLUSTER = 8  # 4KB clusters
    RESERVED_SECTORS = 32    # Boot sector + BPB + FSInfo
    NUM_FATS = 2
    ROOT_ENTRIES = 512
    MEDIA = 0xF8
    FAT_SIZE = 2  # bytes per FAT entry for FAT16

    total_sectors = IMAGE_SIZE // BYTES_PER_SECTOR
    root_dir_sectors = (ROOT_ENTRIES * 32 + BYTES_PER_SECTOR - 1) // BYTES_PER_SECTOR

    # Calculate FAT size in sectors (iterative to handle circular dependency)
    fat_sectors = root_dir_sectors  # Initial estimate
    for _ in range(10):
        data_sectors = total_sectors - RESERVED_SECTORS - (NUM_FATS * fat_sectors) - root_dir_sectors
        data_clusters = data_sectors // SECTORS_PER_CLUSTER
        fat_entries = data_clusters + 2
        new_fat_sectors = (fat_entries * FAT_SIZE + BYTES_PER_SECTOR - 1) // BYTES_PER_SECTOR
        if new_fat_sectors == fat_sectors:
            break
        fat_sectors = new_fat_sectors

    data_sectors = total_sectors - RESERVED_SECTORS - (NUM_FATS * fat_sectors) - root_dir_sectors
    data_clusters = data_sectors // SECTORS_PER_CLUSTER

    root_dir_sector = RESERVED_SECTORS + (NUM_FATS * fat_sectors)
    data_sector = root_dir_sector + root_dir_sectors
    bytes_per_cluster = SECTORS_PER_CLUSTER * BYTES_PER_SECTOR

    print(f"FAT16 Layout:")
    print(f"  Total sectors: {total_sectors}")
    print(f"  Bytes/sector: {BYTES_PER_SECTOR}")
    print(f"  Sectors/cluster: {SECTORS_PER_CLUSTER}")
    print(f"  Reserved: {RESERVED_SECTORS}")
    print(f"  FATs: {NUM_FATS}")
    print(f"  Root entries: {ROOT_ENTRIES}")
    print(f"  FAT sectors: {fat_sectors}")
    print(f"  Root dir sector: {root_dir_sector}")
    print(f"  Data sector: {data_sector}")
    print(f"  Data clusters: {data_clusters}")

    # Create the image
    image = bytearray(IMAGE_SIZE)

    # Step 1: Write boot sector (FAT16 BPB)
    # Jump instruction
    image[0:3] = b'\xEB\x58\x90'  # JMP short + NOP
    # OEM name
    image[3:11] = b'TEARIX    '
    # BPB
    struct.pack_into('<H', image, 11, BYTES_PER_SECTOR)       # bytes per sector
    image[13] = SECTORS_PER_CLUSTER                          # sectors per cluster
    struct.pack_into('<H', image, 14, RESERVED_SECTORS)      # reserved sectors
    image[16] = NUM_FATS                                       # number of FATs
    struct.pack_into('<H', image, 17, ROOT_ENTRIES)          # root entries
    struct.pack_into('<H', image, 19, 0)                   # total sectors (16-bit, 0 if >65535)
    image[21] = MEDIA                                        # media descriptor
    struct.pack_into('<H', image, 22, fat_sectors)           # FAT16 size in sectors
    struct.pack_into('<H', image, 24, 32)                    # sectors per track
    struct.pack_into('<H', image, 26, 64)                    # number of heads
    struct.pack_into('<I', image, 28, 0x80)                 # hidden sectors
    if total_sectors > 65535:
        struct.pack_into('<I', image, 32, total_sectors)    # total sectors (32-bit)
    else:
        struct.pack_into('<I', image, 32, 0)
    # Extended boot signature (0x28 = UEFI)
    image[36] = 0x29
    struct.pack_into('<I', image, 37, 0x12345678)          # volume serial
    image[41:42] = b'TEARIX    '[:1]  # volume label (partial)
    image[42:47] = b'FAT16  '
    # Boot code (minimal)
    image[510:512] = b'\x55\xAA'  # Boot signature

    # Step 2: Write FATs
    def fat_offset(cluster):
        return RESERVED_SECTORS * BYTES_PER_SECTOR + cluster * FAT_SIZE

    def sector_to_offset(sector):
        return sector * BYTES_PER_SECTOR

    # FAT entries 0 and 1 are special
    # FAT[0] = media descriptor (usually 0xFFF8 | MEDIA)
    # FAT[1] = 0xFFFF (end of chain marker)
    for fat_idx in range(NUM_FATS):
        fat_base = RESERVED_SECTORS * BYTES_PER_SECTOR + fat_idx * fat_sectors * BYTES_PER_SECTOR
        struct.pack_into('<H', image, fat_base, 0xFFF8 | MEDIA)  # FAT[0]
        struct.pack_into('<H', image, fat_base + 2, 0xFFFF)      # FAT[1]

    def set_fat(cluster, value):
        for fat_idx in range(NUM_FATS):
            fat_base = RESERVED_SECTORS * BYTES_PER_SECTOR + fat_idx * fat_sectors * BYTES_PER_SECTOR
            struct.pack_into('<H', image, fat_base + cluster * 2, value & 0xFFFF)

    def get_fat(cluster):
        fat_base = RESERVED_SECTORS * BYTES_PER_SECTOR
        return struct.unpack_from('<H', image, fat_base + cluster * 2)[0]

    def cluster_to_offset(cluster):
        return sector_to_offset(data_sector) + (cluster - 2) * bytes_per_cluster

    # Allocate clusters for EFI file
    file_sectors = (len(efi_data) + BYTES_PER_SECTOR - 1) // BYTES_PER_SECTOR
    file_clusters = (file_sectors + SECTORS_PER_CLUSTER - 1) // SECTORS_PER_CLUSTER
    if file_clusters == 0:
        file_clusters = 1

    # Find free clusters starting from 2
    file_cluster_list = []
    cluster = 2
    while len(file_cluster_list) < file_clusters and cluster < data_clusters + 2:
        if get_fat(cluster) == 0:
            file_cluster_list.append(cluster)
            if len(file_cluster_list) == file_clusters:
                set_fat(cluster, 0xFFFF)  # End of chain
            else:
                next_cluster = cluster + 1
                while next_cluster < data_clusters + 2 and get_fat(next_cluster) != 0:
                    next_cluster += 1
                set_fat(cluster, next_cluster)
                cluster = next_cluster
        else:
            cluster += 1

    if len(file_cluster_list) < file_clusters:
        print(f"ERROR: Not enough clusters ({file_sectors} sectors, {file_clusters} clusters needed)")
        sys.exit(1)

    # Write EFI file data
    offset = cluster_to_offset(file_cluster_list[0])
    image[offset:offset + min(len(efi_data), bytes_per_cluster)] = efi_data[:bytes_per_cluster]
    for i in range(1, len(file_cluster_list)):
        offset = cluster_to_offset(file_cluster_list[i])
        start = i * bytes_per_cluster
        end = start + bytes_per_cluster
        image[offset:offset + min(len(efi_data) - start, bytes_per_cluster)] = efi_data[start:end]

    print(f"EFI file: {len(efi_data)} bytes, {file_clusters} clusters starting at {file_cluster_list[0]}")

    # Step 3: Write root directory entries
    # Entry for "EFI" directory (volume label entry first, then directory entry)

    # Root entry 0: Volume label
    root_off = sector_to_offset(root_dir_sector)
    struct.pack_into('11s', image, root_off, b'TEAR-IX    ')  # Volume label (8 chars + 3 ext)
    # Actually, volume label is just the name field (11 bytes), attribute = 0x28
    struct.pack_into('11s', image, root_off, b'TEAR-IX JAM')
    struct.pack_into('<B', image, root_off + 11, 0x28)  # Volume label attribute

    # Root entry 1: EFI directory
    efi_cluster = file_cluster_list[-1] + 1  # Use next available cluster for EFI dir
    set_fat(efi_cluster, 0xFFFF)  # EOF for directory
    efi_entry_off = root_off + 1 * 32
    struct.pack_into('11s', image, efi_entry_off, b'EFI      ')  # "EFI      " + "   "
    struct.pack_into('<B', image, efi_entry_off + 11, 0x10)       # Directory attribute
    struct.pack_into('<H', image, efi_entry_off + 25, efi_cluster)  # Starting cluster
    struct.pack_into('<I', image, efi_entry_off + 27, 0)           # Size (0 for dir)

    # Root entry 2: BOOTX64.EFI (also at root for compatibility)
    efi_file_entry = root_off + 2 * 32
    struct.pack_into('11s', image, efi_file_entry, b'BOOTX64 ')
    struct.pack_into('3s', image, efi_file_entry + 8, b'EFI')
    struct.pack_into('<B', image, efi_file_entry + 11, 0x20)  # Archive
    struct.pack_into('<H', image, efi_file_entry + 25, file_cluster_list[0])
    struct.pack_into('<I', image, efi_file_entry + 27, len(efi_data))

    # Step 4: Write EFI directory contents
    # EFI/ needs: . (current), .. (parent), BOOT/ (subdir)
    efi_dir_off = cluster_to_offset(efi_cluster)
    image[efi_dir_off:efi_dir_off + bytes_per_cluster] = b'\x00' * bytes_per_cluster

    # EFI/. entry (current dir = EFI)
    struct.pack_into('11s', image, efi_dir_off, b'.        ')  # ".       " + "   "
    struct.pack_into('<B', image, efi_dir_off + 11, 0x10)   # Directory
    struct.pack_into('<H', image, efi_dir_off + 25, efi_cluster)
    struct.pack_into('<I', image, efi_dir_off + 27, 0)

    # EFI/.. entry (parent = root)
    dotdot_off = efi_dir_off + 32
    struct.pack_into('11s', image, dotdot_off, b'..       ')
    struct.pack_into('<B', image, dotdot_off + 11, 0x10)   # Directory
    struct.pack_into('<H', image, dotdot_off + 25, 0)  # Root is cluster 0 in FAT16
    struct.pack_into('<I', image, dotdot_off + 27, 0)

    # EFI/BOOT entry (subdirectory)
    boot_cluster = efi_cluster + 1
    set_fat(boot_cluster, 0xFFFF)
    boot_entry_off = efi_dir_off + 2 * 32
    struct.pack_into('11s', image, boot_entry_off, b'BOOT     ')
    struct.pack_into('<B', image, boot_entry_off + 11, 0x10)  # Directory
    struct.pack_into('<H', image, boot_entry_off + 25, boot_cluster)
    struct.pack_into('<I', image, boot_entry_off + 27, 0)

    # Step 5: Write BOOT directory contents
    # BOOT/ needs: . (current), .. (parent), BOOTX64.EFI (file)
    boot_dir_off = cluster_to_offset(boot_cluster)
    image[boot_dir_off:boot_dir_off + bytes_per_cluster] = b'\x00' * bytes_per_cluster

    # BOOT/. entries
    struct.pack_into('11s', image, boot_dir_off, b'.        ')
    struct.pack_into('<B', image, boot_dir_off + 11, 0x10)
    struct.pack_into('<H', image, boot_dir_off + 25, boot_cluster)
    struct.pack_into('<I', image, boot_dir_off + 27, 0)

    struct.pack_into('11s', image, boot_dir_off + 32, b'..       ')
    struct.pack_into('<B', image, boot_dir_off + 32 + 11, 0x10)
    struct.pack_into('<H', image, boot_dir_off + 32 + 25, efi_cluster)
    struct.pack_into('<I', image, boot_dir_off + 32 + 27, 0)

    struct.pack_into('11s', image, boot_dir_off + 64, b'BOOTX64 ')
    struct.pack_into('3s', image, boot_dir_off + 64 + 8, b'EFI')
    struct.pack_into('<B', image, boot_dir_off + 64 + 11, 0x20)  # Archive
    struct.pack_into('<H', image, boot_dir_off + 64 + 25, file_cluster_list[0])
    struct.pack_into('<I', image, boot_dir_off + 64 + 27, len(efi_data))

    print(f"EFI directory at cluster {efi_cluster}")
    print(f"BOOT directory at cluster {boot_cluster}")
    print(f"BOOTX64.EFI -> cluster {file_cluster_list[0]}, size {len(efi_data)}")

    # Write image
    with open(output_path, 'wb') as f:
        f.write(image)

    print(f"FAT16 ESP image written to: {output_path} ({image_size_mb}MB)")


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <efi_binary> <output_img> [size_mb]")
        sys.exit(1)
    efi_bin = sys.argv[1]
    output = sys.argv[2]
    size_mb = int(sys.argv[3]) if len(sys.argv) > 3 else 64
    make_fat16_esp(efi_bin, output, size_mb)
