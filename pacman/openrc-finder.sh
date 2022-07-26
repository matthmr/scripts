#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       openrc-finder.sh"
		echo "Description: Finds all packages that have an \`openrc' equivalent in \`artix'"
		exit 1
esac

if [[ ! -d /tmp/pacman ]]
then
	echo "[ !! ] No \`/tmp/pacman' directory found. Did you run \`~/Scripts/linux.sh'?" 1>&2
	exit 1
fi

echo "[ .. ] Listing all packages..."
pman -Q > /tmp/pacman/pacman-all
echo "[ .. ] Finding openrc scripts; saving to \`~/Hooks/pacman/openrc-using'"
grep -wif /tmp/pacman/pacman-all-files ~/Hooks/pacman/openrc > ~/Hooks/pacman/openrc-using
