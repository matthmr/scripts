#!/usr/bin/sh

if [[ $USER != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

case $1 in
	'-h'|'--help')
		echo "Usage:       ldconfig-update.sh"
		echo "Description: Update libraries on system update"
		exit 1
esac

echo "[ .. ] Updating \`ldconfig's database"

ldconfig

echo "[ OK ] Done"
