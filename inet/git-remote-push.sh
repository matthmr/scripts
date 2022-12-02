#!/usr/bin/sh

AS=${0##*/}

case $1 in
  '-h'|'--help')
    if [[ $AS = 'git-remote-push.sh' ]]; then
      echo "Usage:       git-remote-push.sh [-s] <local-repo> <remote-address> [<remote-name>] -- [git options]"
      echo "Description: Pushes a git repository to the standard remote"
      echo "Options:
  -s: <local-repo> is relative to the standard source, otherwise it's
      relative to the current working directory
  -a <remote-name>: use <remote-name> instead of <local-repo> as the
                    repo name in <remote-address>"
      echo "VARIABLES:
      GIT: [git client]"
    elif [[ $AS = 'git-remote-pull.sh' ]]; then
      echo "Usage:       git-remote-pull.sh [-s] <local-repo> <remote-address> [<remote-name>] -- [git options]"
      echo "Description: Pulls a git repository from the standard remote"
      echo "Options:
  -s: <local-repo> is relative to the standard source, otherwise it's
      relative to the current working directory
  -a <remote-name>: use <remote-name> instead of <local-repo> as the
                    repo name in <remote-address>"
      echo "VARIABLES:
      GIT: [git client]"
    fi
    exit 1;;
esac

[[ -z $GIT ]] && GIT=git

BASE=
REPO=
REMOTE=
REMOTE_REPO=
GIT_OPT=

lock_repo=false lock_git=false
has_repo=false has_remote=false

for arg in $@; do
  if $lock_git; then
    GIT_OPT+=$arg
    continue
  fi

  if [[ $arg = '--' ]]; then
    lock_git=true
    continue
  elif [[ $arg = '-s' ]]; then
    lock_repo=true
    BASE=/home/mh/Git/MH/
    continue
  fi

  if $lock_repo; then
    lock_repo=false
    has_repo=true
    has_std=true
    REPO=$arg
  else
    if $has_repo; then
      if $has_remote; then
        REMOTE_REPO=$arg
      else
        REMOTE=$arg
        has_remote=true
      fi
    else
      REPO=$arg
      has_repo=true
    fi
  fi
done

if [[ $lock_repo = true ]] || [[ $has_repo = false ]]; then
  echo "[ !! ] Missing repo name"
  exit 1
fi

if [[ -z $REMOTE_REPO ]]; then
  REMOTE_REPO=$REPO
fi

if [[ -z $REMOTE ]]; then
  echo "[ !! ] Missing remote"
  exit 1
elif [[ ! $REMOTE =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
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

echo "[ == ] Calling as: $GIT $GIT_OPT -C $BASE$REPO $CMD git://$REMOTE/$REMOTE_REPO"
$GIT $GIT_OPT -C $BASE$REPO $CMD git://$REMOTE/$REMOTE_REPO
