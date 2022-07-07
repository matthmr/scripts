#!/usr/bin/sh

wiki_find_pacman() {
	grep -Frwin -f "$1" /home/mh/Documents/Wiki/ \
		--exclude='*.html'\
		--exclude='*.pdf'\
		--exclude='*.png'\
		--exclude-dir=.git\
		--color=always
}

wiki_find_pacman "$1"
