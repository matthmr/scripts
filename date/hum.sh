#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       date-short.sh"
		echo "Description: Get a formated short date"
		exit 1
esac

date +'%H%M%S'
