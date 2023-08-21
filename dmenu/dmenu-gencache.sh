#!/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       dmenu-gencache.sh"
		echo "Description: Generate \`dmenu' cache"
		exit 1
esac

cachedir=@DMENU_GENCACHE_CACHEDIR@
cache="$cachedir/dmenu_run"

[ ! -e "$cachedir" ] && mkdir -p "$cachedir"

IFS=:
if stest -dqr -n "$cache" $PATH; then
	stest -flx $PATH | sort -u | tee "$cache" >/dev/null
fi

echo "[ OK ] dmenu-gencache.sh: Done"

exit 0
