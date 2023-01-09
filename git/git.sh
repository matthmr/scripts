#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       git.sh"
    echo "Description: Update git-controlled packages"
    exit 1
esac

GITINCLUDE=/home/mh/Scripts/git/gitinclude.txt

while read repo
do

  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]
  then
    continue
  fi

  echo "[ .. ] pulling repository: $repo"
  git -C $repo pull origin -- HEAD
  # git pull origin
done < $GITINCLUDE

echo "[ OK ] Done"
