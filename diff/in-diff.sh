#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       in-diff.sh [--new] [infile]"
		echo "Description: Diffs [infile] with its macro-substituted source, or the opposite"
		echo "Variables:
	DIFF : diff-like command"
		exit 1
esac

if [[ $# = 0 || $# -ge 3 ]]
then
	echo "[ !! ] Bad usage. See in-diff.sh --help" >&2
	exit
fi

NEW=false
if [[ $1 = '--new' ]]
then
	NEW=true
	FILE=$2
elif [[ ${1:0:2} = '--' ]]
then
	echo "[ !! ] Bad usage. See github.sh --help" >&2
	exit 1
else
	FILE=$1
fi

ORIG=${FILE%.in}

if [[ ${ORIG} == ${FILE} ]]
then
  echo "[ !! ] File \`${FILE}' is not an infile"
  exit 1
fi

[[ -z $DIFF ]] && DIFF='/usr/bin/diff --color=always -u'

if $NEW
then
	$DIFF ${ORIG} ${FILE}
else
	$DIFF ${FILE} ${ORIG}
fi
