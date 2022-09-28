#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       wiki-find-pacman [update file]"
		echo "Description: Finds an [update file] on the system wiki source tree with respect to pacman logs"
		exit 1
esac

WIKI=/home/mh/Documents/Org/Wiki/

wiki_find_pacman() {
	grep -Frwin -f "$1" $WIKI \
		--exclude='*.html'\
		--exclude='*.pdf'\
		--exclude='*.png'\
		--exclude-dir=.git\
		--color=always
}

wiki_find_pacman "$1"
