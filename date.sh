#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       date.sh"
		echo "Description: Get a formated date"
		exit 1
esac

date +'%Y%m%d %H%M'
