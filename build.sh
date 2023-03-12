#!/usr/bin/env bash
if [ -z "$1" ]
then
    echo "Usage: ./build.sh destination_image.bin"
    exit 1
fi

./bin/minfs make F160C-minfs minfs.img F160C-minfs/rootfs_ini.tmp
cp original_rom.bin "$1"
dd if=minfs.img of="$1" bs=1024 seek=1088 status=progress conv=notrunc
