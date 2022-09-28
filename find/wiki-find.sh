#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       wiki-find [regex]"
		echo "Description: Finds a [regex] on the system wiki source tree"
		exit 1
esac

WIKI=/home/mh/Documents/Org/Wiki/

wiki_find() {
	grep -rin "$1" $WIKI \
		--exclude='*.html'\
		--exclude='*.pdf'\
		--exclude='*.png'\
		--exclude-dir=.git\
		--color=always
}

wiki_find "$1"
