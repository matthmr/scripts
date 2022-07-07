#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage: ldconfig.sh"
		exit 1
esac

# TODO: set the library prefix as a variable

ldconfig -p |\
awk '{print $4}' |\
grep '^/' --color=never |\
sed 's/\/mnt\/ssd\/root//g' |\
uniq -D
