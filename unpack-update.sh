#!/usr/bin/env bash
set -e

[ $# -ne 1 ] && { 
	echo "Usage:"
	echo "    $0 update_file.img"
	echo "        It unpacks update_file.img into update_file.img.dump, removing the destination directory if it already exists."
	exit 1 
}
cd -- "$(dirname -- "$0")"

UPDATE_FILE=$1

echo "Unpacking update image $UPDATE_FILE into $UPDATE_FILE.dump"
rm -Rf "$UPDATE_FILE.dump"
./bin/awimage -v "$UPDATE_FILE"

echo "Unpacking MINFS image $UPDATE_FILE.dump/data_udisk.fex into $UPDATE_FILE.dump/data_udisk"
mkdir "$UPDATE_FILE.dump/data_udisk"
./bin/minfs dump "$UPDATE_FILE.dump/data_udisk.fex" "$UPDATE_FILE.dump/data_udisk"

