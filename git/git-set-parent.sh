#!/usr/bin/sh

set -e

case $1 in
  '-h'|'--help')
    echo "Usage:       git-set-parent.sh OURS PARENT"
    echo "Description: Set parent of OURS to PARENT"
    exit 0;;
esac

ours=$1
parent=$2

if [[ -z $ours || -z $parent ]]; then
  echo "[ !! ] Wrong usage. See \`--help'"
  exit 1
fi

git cat-file commit $ours |\
  sed -E "s/parent [^ ]+$/parent $(git rev-parse $parent^0)/" > /tmp/.gitcmt

echo "[ .. ] Done. $ours is now parented by $parent"
git hash-object -t commit -w /tmp/.gitcmt
