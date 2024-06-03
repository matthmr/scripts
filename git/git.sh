#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       git.sh FILES..."
    echo "Description: Update git-controlled packages"
    echo "Syntax:      The syntax of the files is the following:

  LOCAL_REPO_ORIGIN [LOCAL_REPO_BRANCH] [REMOTE_REPO_ORIGIN] [REMOTE_REPO_BRANCH]

  Every entry will fetch from REMOTE_REPO_ORIGIN (or origin if empty), given
  branch REMOTE_REPO_BRANCH (or master if empty), to LOCAL_REPO_ORIGIN at branch
  LOCAL_REPO_BRANCH (or master if empty)

    - If LOCAL_REPO_BRANCH has a \`@' in front, then it will not merge, but flag
      that the repository needs to be updated (useful for forks)
      - If using this construct, you need to change REMOTE_REPO_BRANCH to
        have this syntax:

        REMOTE_REF_NAME:LOCAL_REF_NAME (e.g. master:fork-master)

        If REMOTE_REF_NAME is the same as LOCAL_REPO_BRANCH, then you can leave
        it blank
     - You can also ignore the LOCAL_REPO_BRANCH if it is master, using this
       construct, if you leave \`@' by itself, e.g.:

       /path/to/git/repo @ some-origin main:fork-master

       will fetch some-origin main to fork-master, then compare it with master
   - If LOCAL_REPO_BRANCH has a \`*' in front, then it will assume its value as
     the default value of REMOTE_REPO_BRANCH, if it's left empty
   - If LOCAL_REPO_BRANCH has a \`:' in it, separating right hand-side from left
     hand-side, it's equivalent to:

     /path/to/git/repo main:master -> /path/to/git/repo master origin main

     Either side left empty means \`master'

   The constructs above cannot mix with each other"
    exit 1 ;;
  '')
    echo "[ !! ] Missing FILE. See \`--help'"
    exit 1 ;;
esac

function op() {
  local cmd=""
  local post_cmd=false

  local _remote_branch=""
  local _local_branch=""

  local remote_assume

  while read local_repo local_branch remote_repo remote_branch; do
    remote_assume=master

    if [[ $local_repo =~ ^#.*$ || $local_repo =~ ^( \t)*$ ]]; then
      continue
    fi

    [[ -z $remote_repo ]] && remote_repo=origin

    # handle merger
    if [[ $local_branch =~ ^@ ]]; then
      local_branch=${local_branch/@/}
      [[ -z $local_branch ]] && local_branch=master

      if [[ -z $remote_branch ]]; then
        echo "[ !! ] Missing remote branch for merger on $remote_repo"
        continue
      fi

      if [[ $remote_branch =~ : ]]; then
        local lhs=${remote_branch%:*}
        local rhs=${remote_branch#*:}

        if [[ -z $lhs ]]; then
          _remote_branch=master
        else
          _remote_branch=$lhs
        fi

        if [[ -z $rhs ]]; then
          _local_branch=master
        else
          _local_branch=$rhs
        fi

        remote_branch="$_remote_branch:$_local_branch"
      else
        echo "[ !! ] Wrong remote branch format on $remote_repo"
        continue
      fi

      post_cmd=true
      cmd="git -C $local_repo fetch -u --tags $remote_repo -- $remote_branch"

    else
      # assume after *
      if [[ $local_branch =~ ^'*' ]]; then
        local_branch=${local_branch/\*/}
        [[ ! -z $local_branch ]] && remote_assume=$local_branch
      elif [[ $local_branch =~ : ]]; then
        local lhs=${local_branch%:*}
        local rhs=${local_branch#*:}

        [[ -z $lhs ]] && remote_branch=master || remote_branch=$lhs
        [[ -z $rhs ]] && local_branch=master || local_branch=$rhs
      fi

      [[ -z $local_branch ]] && local_branch=master
      [[ -z $remote_branch ]] && remote_branch=$remote_assume

      cmd="git -C $local_repo fetch -u --tags $remote_repo -- $remote_branch:$local_branch"
    fi

    echo "[ .. ] Fetching repository: $local_repo"
    echo "[ == ] Running: $cmd"

    eval $cmd

    checked=$(git rev-parse HEAD)

    if [[ "$(git rev-parse $ref 2>/dev/null)" == "$checked" ]]; then
      ref=$(git stash create "Stashing update on $(date +'%Y%m%d-%w %I%M%p')")

      echo "[ WW ] $local_repo has $local_branch checked out, and with changes\
, stashing them to ($ref)"

      git restore -SW .
    fi

    if $post_cmd; then
      post_cmd="git -C $local_repo merge-base --is-ancestor $_local_branch $local_branch"

      echo "[ == ] Checking merge with: $post_cmd"

      if eval $post_cmd >&/dev/null; then
        echo "  -> OK"
      else
        echo "  -> NEEDS MERGE"
      fi
    fi

    # clean-up, otherwise some weird shit happens
    post_cmd=false
    local_repo=""
    local_branch=""
    remote_repo=""
    remote_branch=""
  done < $1
}

for file in $@; do
  op $file
done

echo "[ OK ] git.sh: Done"

exit 0
