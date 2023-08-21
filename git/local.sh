#!/usr/bin/sh

case $1 in
  '-h'|'--help')
    echo "Usage:       mh-local.sh [update]"
    echo "Description: Update or flag locally git-controlled packages"
    exit 1
esac

OOD=''
GITLOCAL=@MHLOCAL_TXT@
TTY=$(tty)
SHELL=zsh

## Fetch `origin' and merge it with the default branch. If the third field
## exists (i.e. `repo_foreign' is set), then fetch that, instead of `origin'.
## When `repo_foreign' is set, it's assumed the repo has another remote origin
## counter-part (on github, gitlab, or so...). The default branch of the
## original repo has a `fork-' prefix
function fetch_repo {
  local repo_name=''

  while read repo_path repo_branch repo_foreign; do
    if [[ $repo_path =~ ^#.*$ || $repo_path =~ ^( \t)*$ ]]; then
      continue
    fi

    repo_name=${repo_path##*/}

    echo "[ .. ] mh-local.sh: fetching fork repo: $repo_name:$repo_branch"

    if [[ ! -z $repo_foreign ]]; then
      echo "[ == ] Running as: git -C $repo_path fetch $repo_foreign -- \
$repo_branch:$repo_branch"
      git -C $repo_path fetch "$repo_foreign" -- $repo_branch:fork-$repo_branch
    else
      echo "[ == ] Running as: git -C $repo_path fetch origin -- \
$repo_branch:$repo_branch"
      git -C $repo_path fetch origin -- $repo_branch:$repo_branch
    fi
  done < $GITLOCAL
}

## Update repo given the merge branch. We assume the currently checked out
## branch is `local_branch` as per `check_ood'
function update_repo {
  local repo_path=$1
  local merger_branch=$2
  local repo_name=${repo_path##*/}

  printf "[ ?? ] Update $repo_name:$repo_branch? [Y/n] "
  read ans

  if [[ $ans == 'y' || -z $ans ]]; then
    echo "[ !! ] Updating out-of-date $repo_name"

    echo "[ == ] Merging command: git -C $repo_path merge --no-edit $merger_branch"
    if ! GIT_EDITOR=ed \
         git -C $repo_path merge --no-edit $merger_branch; then
      echo "[ !! ] Merge failed. Spawning recovery shell"
      pushd $repo_path
      $SHELL
      popd
    fi
  else
    echo "[ !! ] Ignoring $repo_name:$repo_branch"
  fi
}

# Check to see if the default branch of origin, or repo_foreign, is in the
# history of the local branch, if not, then prompt for update
function check_ood {
  local remote_branch=''
  local local_branch=''
  local repo_name=''
  local repo_cm=''

  while read repo_path repo_branch repo_foreign; do
    if [[ $repo_path =~ ^#.*$ || $repo_path =~ ^( \t)*$ ]]; then
      continue
    fi

    repo_name=${repo_path##*/}

    echo "[ .. ] Checking $repo_name:$repo_branch..."

    if [[ ! -z $repo_foreign ]]; then
      remote_branch=fork-$repo_branch
      local_branch=$repo_branch
    else
      remote_branch=$repo_branch
      local_branch=mh-$repo_branch
    fi

    remote_cm=$(git -C $repo_path rev-parse $remote_branch)

    if ! git -C $repo_path rev-list $local_branch |\
         grep -q -m1 "$remote_cm"; then
      echo "  -> out-of-date (remote's not on local's history)"
      update_repo $repo_path $remote_branch <${TTY}
    else
      echo "  -> up-to-date"
    fi
  done < $GITLOCAL
}

if [[ $1 = 'update' ]]; then
  fetch_repo
fi

check_ood

echo "[ OK ] mh-local.sh: Done"

exit 0
