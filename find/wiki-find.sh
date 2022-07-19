#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       wiki-find [regex]"
		echo "Description: Finds a [regex] on the \`wiki' source tree with respect to pacman logs"
		exit 1
esac


wiki_find() {
	grep -rin "$1" /home/mh/Documents/Wiki/ \
		--exclude='*.html'\
		--exclude='*.pdf'\
		--exclude='*.png'\
		--exclude-dir=.git\
		--color=always
}

wiki_find "$1"
