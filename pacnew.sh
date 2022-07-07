#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage: pacnew.sh FILE"
		echo "Variables: 
	DIFF : diff command"
		exit 1
esac

FILE="$1"
DIFF="diff --color=always -u"

$DIFF $FILE $FILE.pacnew
