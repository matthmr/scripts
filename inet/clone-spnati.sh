#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       clone-spnati-tools.sh"
		echo "Description: Clones \`spnati's kisekae tool bundle"
		echo "Variables:
	CURL : curl-like command"
		exit 1
esac

SPNATI="https://gitgud.io/spnati/spnati"

[[ -z $CURL ]] && CURL=curl

$CURL -L \
"$SPNATI/-/archive/master/spnati-master.tar.gz?path=tools" \
> spnati-tools.tar
