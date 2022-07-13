#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage: bin.sh"
		exit 1
esac

file /home/mh/.local/bin/* |\
awk '
{
	if ($2 == "POSIX" || $2 == "Bourne-Again") {
		print $0
	}
}' |\
awk -F: '{print $1}'
