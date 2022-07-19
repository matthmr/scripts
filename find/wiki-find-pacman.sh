#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       wiki-find-pacman [update file]"
		echo "Description: Finds an [update file] on the \`wiki' source tree with respect to pacman logs"
		exit 1
esac

wiki_find_pacman() {
	grep -Frwin -f "$1" /home/mh/Documents/Wiki/ \
		--exclude='*.html'\
		--exclude='*.pdf'\
		--exclude='*.png'\
		--exclude-dir=.git\
		--color=always
}

wiki_find_pacman "$1"
