#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

BIN_PREFIX=/mnt/ssd/root/usr/bin

echo "[ .. ] Editing firefox path"
sed -i 's/exec \/usr/exec \/mnt\/ssd\/root\/usr/g' $BIN_PREFIX/firefox
echo "[ .. ] Done!"
