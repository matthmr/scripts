#!/usr/bin/bash

set -e

case $1 in
  '--help'|'-h')
    echo "Usage:       git-merge-these.sh <MERGER-BASE> [MERGER-DIFF]"
    echo "Description: Returns a list of files which need to be checked \
given the merger-base, and optionally its diff (generally in the form of the \
stash or a tag). Without MERGER-DIFF, tries to generate given the previous \
commit, unless it doesn't exist, in which case it'll panic lmao, The merge \
occurs with the current HEAD as MERGER-ONTO"
    exit 0;;
  *)
    MERGER_BASE=$1;;
esac

if [[ -z $MERGER_BASE ]]; then
  echo "[ !! ] Missing merger base"
  exit 1
fi

if [[ -z $2 ]]; then
  echo "[ WW ] Using previous commit as base, MERGER-BASE as MERGER-DIFF" 1>&2
  MERGER_BASE=$1~1
  MERGER_DIFF=$1
else
  MERGER_DIFF=$2
fi

git diff-index $MERGER_BASE > /tmp/git-merger-base

git diff-index $MERGER_DIFF |\
  diff /tmp/git-merger-base - |\
  awk '/^[<>]/ {printf "%s %s %s\n", $1, $6, $7}' | sort -uk3

rm -f /tmp/git-merger-base
