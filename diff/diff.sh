#!/usr/bin/bash

case $1 in
  '-h'|'--help')
    echo "Usage:       diff.sh [-d] [-] [file] [+] [file] -- [diff-opts]"
    echo "Description: Verbose diff"
    echo "Options:
  -:  take [file] as the file with the missing lines
  +:  take [file] as the file with the added lines
  -d: use default diff"
    echo "Variables:
  DIFF=\`diff'-like command"
    exit 1;;
esac

[[ -z $DIFF ]] && DIFF='diff --color=always -u'

function die {
  echo "[ !! ] Bad usage. See --help"
  exit 1
}

has_minus=false
has_plus=false
escape=false

lock_minus=false
lock_plus=false

DIFF_OPT=""
MINUS_FILE=""
PLUS_FILE=""

for arg in $@; do
  if $escape; then
    DIFF_OPT+=" $arg"
    continue
  elif $lock_minus; then
    lock_minus=false
    if $has_minus; then
      die
    fi
    has_minus=true
    MINUS_FILE="$arg"
    continue
  elif $lock_plus; then
    lock_plus=false
    if $has_plus; then
      die
    fi
    has_plus=true
    PLUS_FILE="$arg"
    continue
  fi

  case $arg in
    '-d')
      DIFF=diff;;
    '-')
      lock_minus=true;;
    '+')
      lock_plus=true;;
    '--')
      escape=true;;
    *)
      if ! $has_minus; then
        has_minus=true
        MINUS_FILE="$arg"
      elif ! $has_plus; then
        has_plus=true
        PLUS_FILE="$arg"
      else
        die
      fi
  esac
done

if [[ -z $MINUS_FILE ]] || [[ -z $PLUS_FILE ]]; then
  die
fi

echo "[ == ] Running as: $DIFF $DIFF_OPT $MINUS_FILE $PLUS_FILE" 1>&2
$DIFF $DIFF_OPT $MINUS_FILE $PLUS_FILE
