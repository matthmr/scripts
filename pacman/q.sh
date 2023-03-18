#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       q.sh [FILE]"
		echo "Description: cron-like job hook"
		exit 1
esac

PACMAN=pacman
DATE=$(date +'%Y%m%d')

$PACMAN -Q > /home/mh/Analysis/Pacman/Q/$DATE.color

sed -E 's.\x1b\[(0;1|1;32|0)m..g' /home/mh/Analysis/Pacman/Q/$DATE.color \
	> /home/mh/Analysis/Pacman/Q/$DATE

echo "[ OK ] Done"
