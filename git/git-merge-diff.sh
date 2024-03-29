#!/bin/sh

set -e

case $1 in
  '--help'|'-h')
    echo "Usage:       git-merge-diff.sh <file>"
    echo "Description: Displays a diff of successfully merged changes, where \
the file may conflict"
    exit 0;;
  *)
    FILE=$1;;
esac

if [[ -z $FILE ]]; then
  echo "[ !! ] Missing file"
  exit 1
fi

if [[ ! -f $FILE ]]; then
  echo "[ !! ] Not a file"
  exit 1
fi

# select the first one as the default in case of merge conflicts
awk '
BEGIN {p = 1;}
/^<<<<<<</ {next}
/^\|\|\|\|\|\|\|/ || /^=======/ {p = 0; next}
/^>>>>>>>/ {p = 1; next}
{if (p) print;}' $FILE > /tmp/git-merge-diff

git show @:$FILE | diff -u - /tmp/git-merge-diff |\
  sed "s:^\(---\|+++\) \(-\|/tmp/git-merge-diff\):\1 $FILE:"

rm /tmp/git-merge-diff
