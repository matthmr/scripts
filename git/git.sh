#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       git.sh"
    echo "Description: Update git-controlled packages"
    exit 1
esac

GITLIST=@GIT_TXT@

while read repo; do
  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]; then
    continue
  fi

  echo "[ .. ] pulling repository: $repo"
  echo "[ == ] Running as: git -C $repo pull origin -- HEAD"

  git -C $repo pull --tags origin -- HEAD
done < $GITLIST

echo "[ OK ] git.sh: Done"

exit 0
