#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       artix-update.sh"
		echo "Description: Find all packages suitable for update in \`artix'"
		exit 1
esac

echo "[ .. ] Fiding updatable \`artix' packages on \`/tmp/pacman/pacman-artix'"
{
	grep -E '(^e[^2x]|udev|.*-openrc)' /tmp/pacman/pacman-artix
} || {
	echo "[ !! ] Not found any updatable package for \`artix'" 1>&2
}
