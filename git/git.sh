#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       git.sh"
    echo "Description: Update git-controlled packages"
    exit 1
esac

GITLIST=/home/mh/Scripts/git/git.txt

while read repo; do
  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]; then
    continue
  fi

  echo "[ .. ] pulling repository: $repo"
  git -C $repo pull origin -- HEAD
done < $GITLIST

echo "[ OK ] git.sh: Done"

exit 0
