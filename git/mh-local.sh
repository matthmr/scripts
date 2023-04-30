#!/usr/bin/sh

case $1 in
  '-h'|'--help')
    echo "Usage:       mh-local.sh [update]"
    echo "Description: Update or flag locally git-controlled packages"
    exit 1
esac

OOD=''
GITLOCAL='/home/mh/Scripts/git/mh-local.txt'
TTY=$(tty)
SHELL=zsh

function fetch_repo {
  while read repo_path repo_branch repo_foreign; do
    if [[ $repo_path =~ ^#.*$ || $repo_path =~ ^( \t)*$ ]]; then
      continue
    fi

    local repo_name=${repo_path##*/}

    if [[ ! -z $repo_foreign ]]; then
      echo "[ .. ] mh-local.sh: fetching fork repo: $repo_name:$repo_branch"
      echo "[ == ] Running as: git -C $repo_path fetch $repo_foreign -- \
$repo_branch:$repo_branch"
      git -C $repo_path fetch "$repo_foreign" -- $repo_branch:fork-$repo_branch
    else
      echo "[ .. ] mh-local.sh: fetching repo: $repo_name:$repo_branch"
      echo "[ == ] Running as: git -C $repo_path fetch origin -- \
$repo_branch:$repo_branch"
      # fetch and merge: the original branch is kept intact, so merging should
      # be the same as just fast-forwarding
      git -C $repo_path fetch origin -- $repo_branch:$repo_branch
    fi

    repo_foreign=
  done < $GITLOCAL
}

function update_repo {
  local repo_path=$1
  local repo_branch=$2
  local repo_foreign=$3

  local repo_name=${repo_path##*/}

  printf "[ ?? ] Update $repo_name:$repo_branch? [Y/n] "
  read ans

  local merge_repo=''

  if [[ $ans == 'y' || -z $ans ]]; then
    echo "[ !! ] Updating out-of-date $repo_name"

    if [[ ! -z $repo_foreign ]]; then
      merge_branch=fork-$repo_branch
    else
      merge_branch=$repo_branch
    fi

    echo "[ == ] Merging command: git -C $repo_path merge --no-edit $repo_branch"
    if ! GIT_EDITOR=ed git -C $repo_path merge --no-edit $merge_branch; then
      echo "[ !! ] Merge failed. Spawning recovery shell"
      pushd $repo_path
      $SHELL
      popd
    fi
  else
    echo "[ !! ] Ignoring $repo_name:$repo_branch"
  fi
}

function check_ood {
  while read repo_path repo_branch repo_foreign; do
    if [[ $repo_path =~ ^#.*$ || $repo_path =~ ^( \t)*$ ]]; then
      continue
    fi

    local repo_name=${repo_path##*/}

    echo "[ .. ] Checking $repo_name:$repo_branch..."

    local fork_branch=''
    local local_branch=''

    if [[ ! -z $repo_foreign ]]; then
      fork_branch=$repo_branch
      local_branch=fork-$repo_branch
    else
      fork_branch=mh-local
      local_branch=$repo_branch
    fi

    local repo_cm=$(git -C $repo_path rev-list $local_branch | head -1)

    # if $repo_branch's commit is not in the history of mh-local, we trigger
    # out-of-date
    if ! git -C $repo_path rev-list $fork_branch | grep -q -m1 "$repo_cm"; then
      echo "  -> out-of-date (master not on mh-local's history)"
      update_repo $repo_path $repo_branch $repo_foreign <${TTY}
    else
      echo "  -> up-to-date"
    fi

    repo_foreign=
  done < $GITLOCAL
}

if [[ $1 = 'update' ]]; then
  fetch_repo
fi

check_ood

echo "[ OK ] mh-local.sh: Done"

exit 0
