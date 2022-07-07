#!/usr/bin/sh

wiki_find() {
	grep -rwin "$1" /home/mh/Documents/Wiki/ \
		--exclude='*.html'\
		--exclude='*.pdf'\
		--exclude='*.png'\
		--exclude-dir=.git\
		--color=always
}

wiki_find "$1"
