#!/usr/bin/env bash
set -e

if [ -z "$2" ]
then
    echo "Usage: ./embed_volumes.sh source_directory destination_image.bin"
    exit 1
fi

echo "Removing old files"
rm -Rf "$1/minfs.img"


DISKNAME=`hdiutil attach "$2/gpt.img" -nomount | grep "GUID_partition_scheme" | cut -d' ' -f1`
echo "Attached GPT image to $DISKNAME"

echo "Extracting volume 1 to $2/1.img"
dd if="${DISKNAME}s1" of="$2/1.img" status=progress

echo "Extracting MINFS volume to $2/minfs.img"
dd if="${DISKNAME}s2" of="$2/minfs.img" status=progress

echo "Extracting FAT volume to $2/fat.img"
dd if="${DISKNAME}s3" of="$2/fat.img" status=progress

echo "Detaching $DISKNAME"
hdiutil detach "$DISKNAME"

echo "Unpacking MINFS to $2/minfs"
mkdir -p "$2/minfs"
./bin/minfs dump "$2/minfs.img" "$2/minfs"

echo "Replacing  GPT image to $2/gpt.img"
dd if="$1" of="$2/gpt.img" bs=1024 skip=48 status=progress
