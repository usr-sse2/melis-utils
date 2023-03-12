#!/usr/bin/env bash
if [ -z "$3" ]
then
    echo "Usage: ./embed_gpt.sh src_firmware_image.bin src_gpt_image.img dst_firmware_image.bin"
    exit 1
fi

cp "$1" "$3"
dd if="$2" of="$3" bs=1024 seek=48 status=progress conv=notrunc
