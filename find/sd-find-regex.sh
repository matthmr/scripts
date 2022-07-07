#!/usr/bin/sh

sd_find() {
	grep -rin "$1" /home/mh/Git/MH/sd/ \
		--exclude='tags'\
		--exclude='Doxyfile'\
		--exclude='*.[oa]'\
		--exclude='*.html'\
		--exclude-dir=.git\
		--exclude-dir='*cache'\
		--color=always
}

sd_find "$1"
