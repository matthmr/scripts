#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       wiki-find-pacman-index [update file]"
		echo "Description: Finds an [update file] on the \`Journa/Index' source tree with respect to pacman manually-tracked packages"
		exit 1
esac

wiki_find_pacman_index() {
	grep -win -f "$1" /home/mh/Documents/Wiki/Journal/Index/pacman.md
}

wiki_find_pacman_index "$1"
