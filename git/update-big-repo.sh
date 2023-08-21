#!/usr/bin/bash

## NOTE: big repos have to have `master` as the checked out branch, even if
## changes were made to them

case $1 in
  '-h'|'--help')
    echo "Usage:       ./update-big-repo.sh"
    echo "Description: Updates a big repositories"
    exit 1;;
esac

BIG_SRC=@BIG_TXT@

while read repo; do
  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]; then
    continue
  fi

  echo "[ == ] Running as: git -C $repo pull origin --depth=1 --rebase -X theirs"
  git -C $repo pull origin --depth=1 --rebase -X theirs
done < $BIG_SRC
