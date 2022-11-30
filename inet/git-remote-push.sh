#!/usr/bin/sh

AS=${0##*/}

case $1 in
  '-h'|'--help')
    if [[ $AS = 'git-remote-push.sh' ]]; then
      echo "Usage:       git-remote-push.sh <repo> <remote>"
      echo "Description: Pushes a git repository to the standard remote"
      echo "VARIABLES:
      GIT: [git client]"
    elif [[ $AS = 'git-remote-pull.sh' ]]; then
      echo "Usage:       git-remote-pull.sh <repo> <remote>"
      echo "Description: Pulls a git repository from the standard remote"
      echo "VARIABLES:
      GIT: [git client]"
    fi
    exit 1;;
esac

[[ -z $GIT ]] && GIT=git

BASE=/home/mh/Git/MH

REPO=$1
REMOTE=$2

if [[ -z $REPO || -z $REMOTE ]]; then
  echo "[ !! ] Wrong usage. See --help"
  exit 1
fi

if [[ ! -d $BASE/$REPO ]]; then
  echo "[ !! ] Repo \`$REPO' is not a standard repo"
  exit 1
fi

if [[ ! $REMOTE =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
  echo "[ !! ] Remote \`$REMOTE' is not an ip address"
  exit 1
fi

CMD=
case $AS in
  'git-remote-pull.sh')
    CMD=pull;;
  'git-remote-push.sh')
    CMD=push;;
esac

echo "[ == ] Calling as: $GIT -C $BASE/$REPO $CMD git://$REMOTE/$REPO"
$GIT -C $BASE/$REPO $CMD git://$REMOTE/$REPO
