#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       sd-find.sh [word]"
		echo "Description: Finds a [word] on the \`SD' source tree"
		exit 1
esac


sd_find() {
	grep -rwin "$1" /home/mh/Git/MH/sd/ \
		--exclude='tags'\
		--exclude='Doxyfile'\
		--exclude='*.[oa]'\
		--exclude='*.html'\
		--exclude-dir=.git\
		--exclude-dir='*cache'\
		--color=always
}

sd_find "$1"
