#!/usr/bin/bash

AS=${0##*/}

function help {
  local USAGE=$1
  local DESC=$2

  echo "Usage:       $USAGE"
	echo "Description: $DESC"
  echo "Variables:
  GREP=\`grep'-like command
  GREP_OPT=\`grep'-like command options"
  exit 1
}

[[ -z $GREP ]] && GREP='grep --color'
GREP_OPTS=''
GREP_BASE=''

case $AS in
  'wiki-find.sh')
    if [[ $1 = '-h' || $1 = '--help' ]]; then
      help "wiki-find [regex]" \
           "Finds a [regex] on the system wiki source tree"
    fi
    GREP_OPTS=-rin
    GREP_BASE=/home/mh/Documents/Org/Wiki/;;
  'journal-find.sh')
    if [[ $1 = '-h' || $1 = '--help' ]]; then
      help "journal-find [regex]" \
           "Finds a [regex] on the system journal source tree"
    fi
    GREP_OPTS='-rin'
    GREP_BASE=/home/mh/Documents/Org/Journal/;;
  'wiki-find-index.sh')
    if [[ $1 = '-h' || $1 = '--help' ]]; then
      help "wiki-find-index [index file]" \
           "Finds strings in the [index file] on the system wiki source tree"
    fi
    GREP_OPTS='-win -f'
    GREP_BASE="/home/mh/Documents/Org/Wiki/sys/pman/pacman-track.org\
 /home/mh/Documents/Org/Wiki/sys/local.org";;
  *)
    echo "[ !! ] Unimplemented usage"
    exit 1;;
esac

[[ -z "$1" ]] && {
  echo "[ !! ] Bad usage. See --help"
  exit 1
}

$GREP $GREP_OPTS "$1" $GREP_BASE \
		  --exclude='*.html'         \
		  --exclude='*.pdf'          \
		  --exclude='*.png'          \
		  --exclude-dir=.git         \
      $GREP_OPT
