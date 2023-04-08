#!/usr/bin/bash

case $1 in
  '-h'|'--help')
    echo "Usage:       ./update-big-repo.sh"
    echo "Description: Updates a big repositories"
    exit 1;;
esac

BIG_SRC=/home/mh/Scripts/git/big.txt

while read repo; do
  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]; then
    continue
  fi

  echo "[ == ] Running as: git -C $repo pull origin --depth=1 --rebase -X theirs"
  git -C $repo pull origin --depth=1 --rebase -X theirs
done < $BIG_SRC
