#!/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       dmenu-gencache.sh"
		echo "Description: Generate \`dmenu' cache"
		exit 1
esac

cachedir="/home/mh/.cache/"
cache="$cachedir/dmenu_run"

[ ! -e "$cachedir" ] && mkdir -p "$cachedir"

IFS=:
if stest -dqr -n "$cache" $PATH; then
	stest -flx $PATH | sort -u | tee "$cache" >/dev/null
fi
