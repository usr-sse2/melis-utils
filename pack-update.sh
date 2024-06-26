#!/usr/bin/env bash
set -e
[ $# -ne 1 ] && { 
	echo "Usage:"
	echo "    $0 update_file.img"
	echo "        (WITHOUT .dump)"
	echo "        It packs update_file.img.dump into update_file.img, overwriting the destination file if it already exists."
	exit 1 
}

SCRIPT_DIR="$(dirname -- "$0")"

if [[ -d $1 ]]; then
    echo "Argument should be the destination image, not the .dump directory"
    exit 1
fi

UPDATE_FILE=$1
rm -f "$UPDATE_FILE"

rm -Rf "$UPDATE_FILE.dump/Language.bak"
cp -R "$UPDATE_FILE.dump/data_udisk/apps/Language" "$UPDATE_FILE.dump/Language.bak"
for file in "$UPDATE_FILE.dump/data_udisk/apps/Language"/*.txt
do
  localidiff replace-unsupported-characters "$file"
  localidiff copy-missing-strings "$file" 21 9
  for language in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21
  do
    localidiff copy-missing-strings "$file" $language 0
  done
done

export ASAN_OPTIONS=detect_leaks=0

echo "Packing $UPDATE_FILE.dump/data_udisk into MINFS image $UPDATE_FILE.dump/data_udisk.fex"
"$SCRIPT_DIR"/bin/minfs make "$UPDATE_FILE.dump/data_udisk" "$UPDATE_FILE.dump/data_udisk.fex" "$UPDATE_FILE.dump/data_udisk/rootfs_ini.tmp"

echo "Updating checksum of $UPDATE_FILE.dump/data_udisk.fex in $UPDATE_FILE.dump/Vdata_udisk.fex"
"$SCRIPT_DIR"/bin/add_checksum "$UPDATE_FILE.dump/data_udisk.fex" "$UPDATE_FILE.dump/Vdata_udisk.fex"

echo "Updating checksum of $UPDATE_FILE.dump/melis_pkg_nor.fex in $UPDATE_FILE.dump/Vmelis_pkg_nor.fex"
"$SCRIPT_DIR"/bin/add_checksum "$UPDATE_FILE.dump/melis_pkg_nor.fex" "$UPDATE_FILE.dump/Vmelis_pkg_nor.fex"

echo "Packing $UPDATE_FILE.dump into update image $UPDATE_FILE"
"$SCRIPT_DIR"/bin/awimage -v -n "$UPDATE_FILE.dump"

rm -Rf "$UPDATE_FILE.dump/data_udisk/apps/Language"
mv "$UPDATE_FILE.dump/Language.bak" "$UPDATE_FILE.dump/data_udisk/apps/Language"
