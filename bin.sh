#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       bin.sh"
		echo "Description: Find \`~/.local/bin' files that also are shell scripts"
		exit 1
esac

file /home/mh/.local/bin/* |\
awk '
{
	if ($0 ~ /text executable/) {
		print $0
	}
}' |\
awk -F: '{print $1}'
