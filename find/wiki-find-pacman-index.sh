#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       wiki-find-pacman-index [update file]"
		echo "Description: Finds an [update file] on the system wiki tracker"
		exit 1
esac

PACMAN_INDEX=/home/mh/Documents/Org/Wiki/System/Pacman/pacman-track.org

wiki_find_pacman_index() {
	grep -win -f "$1" $PACMAN_INDEX
}

wiki_find_pacman_index "$1"
