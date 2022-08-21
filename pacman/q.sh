#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       q.sh [FILE]"
		echo "Description: cron-like job hook"
		exit 1
esac

PACMAN=pman
PACMAN_ARTIX=pmanrc
DATE=$(date +'%Y%m%d')

$PACMAN -Q > /home/mh/Analysis/Pacman/Q/$DATE.color
$PACMAN_ARTIX -Q > /home/mh/Analysis/Pacman/Q/$DATE-artix.color

sed -E 's.\x1b\[(0;1|1;32|0)m..g' /home/mh/Analysis/Pacman/Q/$DATE.color \
	> /home/mh/Analysis/Pacman/Q/$DATE
sed -E 's.\x1b\[(0;1|1;32|0)m..g' /home/mh/Analysis/Pacman/Q/$DATE-artix.color \
	> /home/mh/Analysis/Pacman/Q/$DATE-artix

echo "[ OK ] Done"
