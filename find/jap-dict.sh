#!/usr/bin/bash

case $1 in
	'-h'|'--help')
		echo "Usage:       jap-dict.sh -jre [word]"
		echo "Description: Searches the default japanese dictionary for [word]"
    echo "Options:
  DEFAULT: -j

  -j: search in japanese
  -r: search in romaji
  -e: search in english"
    echo "Variables:
  GREP=\`grep'-like command
  JAPDICT=japanese dictionary path"
		exit 1;;
esac

[[ -z $JAPDICT ]] && JAPDICT=@JAP_DICT_EDICT@
[[ -z $GREP ]]    && GREP=grep

case $1 in
  '-j'|'-e')
    $GREP --color=auto -F "${@:2}" $JAPDICT;;
  '-r')
    $GREP --color=auto -F "$(romaji "${@:2}")" $JAPDICT;;
  *)
    $GREP --color=auto -F "${@:1}" $JAPDICT;;
esac
