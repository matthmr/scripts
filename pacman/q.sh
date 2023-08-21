#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       q.sh [FILE]"
		echo "Description: schedl job hook"
		exit 1
esac

PACMAN=pacman
DATE=$(date +'%Y%m%d')

$PACMAN -Q > @Q_DIR@/$DATE.color

sed -E 's.\x1b\[(0;1|1;32|0)m..g' @Q_DIR@/$DATE.color > @Q_DIR@/$DATE

echo "[ OK ] Done"
