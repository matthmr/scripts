#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

case $1 in
	'-h'|'--help')
		echo "Usage:       vscodium.sh"
		echo "Description: Updates \`vscodium's BAD configure script installation"
		exit 1
esac

ROOT=/mnt/ssd/root
PREFIX=$ROOT/opt/vscodium-bin

echo "[ .. ] Editing vscodium path"
ln --verbose -sf $PREFIX/codium $ROOT/bin/vscodium
ln --verbose -sf $PREFIX/codium $ROOT/bin/codium
echo "[ .. ] Done!"
