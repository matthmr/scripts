#!/usr/bin/bash

set -e

plain=false

case $1 in
  '--help'|'-h')
    echo "Usage:       git-merge-these.sh [OPTIONS] <MERGER-BASE> [MERGER-DIFF]"
    echo "Description: Returns a list of files which need to be checked \
given the merger-base, and optionally its diff (generally in the form of the \
stash or a tag). Without MERGER-DIFF, tries to generate given the previous \
commit, unless it doesn't exist, in which case it'll panic lmao. The merge \
occurs with the current HEAD as MERGER-ONTO"
    echo "Options:
  -p: return plain list"
    exit 0;;
  '-p')
    plain=true
    MERGER_BASE=$2;;
  *)
    MERGER_BASE=$1;;
esac

if [[ -z $MERGER_BASE ]]; then
  echo "[ !! ] Missing merger base"
  exit 1
fi

if $plain; then
  if [[ -z $3 ]]; then
    echo "[ WW ] Using previous commit as base, MERGER-BASE as MERGER-DIFF" 1>&2
    MERGER_BASE=$2~1
    MERGER_DIFF=$2
  else
    MERGER_DIFF=$3
  fi
else
  if [[ -z $2 ]]; then
    echo "[ WW ] Using previous commit as base, MERGER-BASE as MERGER-DIFF" 1>&2
    MERGER_BASE=$1~1
    MERGER_DIFF=$1
  else
    MERGER_DIFF=$2
  fi
fi

git diff-index $MERGER_BASE > /tmp/git-merger-base

if $plain; then
  git diff-index $MERGER_DIFF |\
    diff /tmp/git-merger-base - |\
    awk '/^[<>]/ {printf "%s %s %s %s\n", $1, $2, $6, $7}' | sort -uk3 |\
    awk '{printf "%s ", $4}'
else
  git diff-index $MERGER_DIFF |\
    diff /tmp/git-merger-base - |\
    awk '/^[<>]/ {printf "%s %s %s %s\n", $1, $2, $6, $7}' | sort -uk3
fi

rm -f /tmp/git-merger-base
