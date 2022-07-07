#!/usr/bin/sh

[[ -z $GHUSER ]] && GHUSER=matthmr
[[ -z $GHREPO ]] && GHREPO=sd

case $1 in
	'-h'|'--help')
		echo "Usage: github.sh [--old] <repository:branch> <file path>"
		echo "Variables:
	GHUSER : default user
	CURL : curl-like command
	DIFF : diff-like command"
		exit 1
esac

if [[ $# = 1 || $# -ge 4 ]]
then
	echo "[ !! ] Bad usage. See github.sh --help" >&2
	exit
fi

OFFSET=0
if [[ $1 = '--old' ]]
then
	OFFSET=1
elif [[ ${1:0:2} = '--' ]]
then
	echo "[ !! ] Bad usage. See github.sh --help" >&2
	exit 1
fi

[[ -z $CURL ]] && CURL=curl
[[ -z $DIFF ]] && DIFF='/usr/bin/diff --color=always -u'

REPO=
BRANCH=
function sep {
	local VAR="$1"
	if [[ ${VAR#*:} = "$VAR" ]] # assume 'master'
	then
		BRANCH='master'
		REPO="$VAR"
	else
		BRANCH=${VAR#*:}
		REPO=${VAR%:*}
	fi
}

FILE=
function exist {
	FILE=$1
	{
		[[ ! -f $FILE ]]
	} && {
		exit 1
	}
}

_OFFSET=$OFFSET
this=0
for var in $@
do

	if [[ $OFFSET = 1 ]]
	then
		OFFSET=0
		continue
	fi

	if [[ $this = 1 ]]
	then
		exist "$var"

	else
		sep "$var"
		this=1
	fi

done
OFFSET=$_OFFSET

DIFF1=
DIFF2=

if [[ $OFFSET = 1 ]]
then
	DIFF1="$FILE"
	DIFF2='-'
else
	DIFF1='-'
	DIFF2="$FILE"
fi

GITHUB="https://raw.githubusercontent.com/$GHUSER/$REPO/$BRANCH"
$CURL -s "$GITHUB/$FILE" | $DIFF $DIFF1 $DIFF2
