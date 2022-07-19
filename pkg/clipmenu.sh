#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

case $1 in
	'-h'|'--help')
		echo "Usage:       clipmenu.sh"
		echo "Description: Updates \`clipmenu's script with \`sed'"
		exit 1
esac

BIN_PREFIX=/mnt/ssd/root/usr/bin

echo "[ .. ] Forcing clipdel to delete all clips on \`clipdel\` call"
sed -i 's/CM_REAL_DELETE=0$/CM_REAL_DELETE=1/g' $BIN_PREFIX/clipdel

echo "[ .. ] Done!"
