#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

BIN_PREFIX=/mnt/ssd/root/usr/bin

echo "[ .. ] Forcing clipdel to delete all clips on \`clipdel\` call"
sed -i 's/CM_REAL_DELETE=0$/CM_REAL_DELETE=1/g' $BIN_PREFIX/clipdel


echo "[ .. ] Done!"
