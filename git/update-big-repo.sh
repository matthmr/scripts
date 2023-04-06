#!/usr/bin/bash

case $1 in
  '-h'|'--help')
    echo "Usage:       ./update-big-repo.sh"
    echo "Description: Updates a big repositories"
    exit 1;;
esac

BIG_SRC=/home/mh/Scripts/git/big.txt

git -C "$1" pull origin --depth=1 --rebase -X theirs

while read repo; do
  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]; then
    continue
  fi

  CMD=$(git_cmd $repo)

  echo "[ == ] Running as: git -C $repo pull origin --depth=1 --rebase -X theirs"
  git -C $repo pull origin --depth=1 --rebase -X theirs
done < $BIG_SRC
