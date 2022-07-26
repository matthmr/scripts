#!/usr/bin/sh

echo "#[ Running root scripts ... ]"

echo "[ Setting up \`tmp' ]"
TMP=$(mktemp -d "/tmp/pacman.XXX")

echo "[ Updating pacman's database ]"
/home/mh/.local/bin/pman -Sy

echo "[ Updating artix's pacman's database ]"
/home/mh/.local/bin/pmanrc -Sy

echo "[ Generating update file for pacman ]"
/home/mh/.local/bin/pman -Qu > $TMP/pacman-raw
/bin/sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/pacman-raw | awk '{print $1}' > $TMP/pacman

echo "[ Generating update file for artix's pacman ]"
/home/mh/.local/bin/pmanrc -Qu > $TMP/pacman-artix-raw
/bin/sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/pacman-artix-raw | awk '{print $1}' > $TMP/pacman-artix

echo "[ Setting persmissions for pacman-related files ]"
chown -Rv mh:mh $TMP
chmod -Rv a+w $TMP

echo "[ Synchronizing clock ]"
./sync-clock.sh

echo "[ Moving tmp to a standardised location ]"
mv -v $TMP /tmp/pacman

echo "[ Done with root scripts! ]"

exit 0
