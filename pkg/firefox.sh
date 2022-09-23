#!/usr/bin/sh

#if [[ "$USER" != 'root' ]]
#then
#	echo "[ !! ] Need to be root"
#	exit 1
#fi

case $1 in
	'-h'|'--help')
		echo "Usage:       firefox.sh"
		echo "Description: Updates \`firefox's script with \`sed'"
		exit 1
esac

BIN_PREFIX=/mnt/ssd/root/usr/bin

echo "[ .. ] Editing firefox path"
sed -i 's/exec \/usr/exec \/mnt\/ssd\/root\/usr/g' $BIN_PREFIX/firefox
echo "[ .. ] Done!"
