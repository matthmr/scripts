#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       git.sh FILES..."
    echo "Description: Update git-controlled packages"
    exit 1 ;;
  '')
    echo "[ !! ] Missing FILE. See \`--help'"
    exit 1 ;;
esac

function op() {
  local cmd=""

  local _remote_branch=""
  local _local_branch=""

  local remote_assume

  while read local_repo local_branch remote_repo remote_branch; do
    remote_assume=master

    if [[ $local_repo =~ ^#.*$ || $local_repo =~ ^( \t)*$ ]]; then
      continue
    fi

    # handle `*LOCAL_BRANCH`: set `remote_assume' to LOCAL_BRANCH
    if [[ $local_branch =~ ^'*' ]]; then
      local_branch=${local_branch/\*/}
      [[ ! -z $local_branch ]] && remote_assume=$local_branch

    # handle `REMOTE_BRANCH:LOCAL_BRANCH`: set them
    elif [[ $local_branch =~ : ]]; then
      local lhs=${local_branch%:*}
      local rhs=${local_branch#*:}

      [[ -z $lhs ]] && remote_branch=master || remote_branch=$lhs
      [[ -z $rhs ]] && local_branch=master || local_branch=$rhs
    fi

    # handle `.': set as default
    [[ -z $local_branch || $local_branch == '.' ]] && local_branch=master
    [[ -z $remote_branch || $remote_branch == '.' ]] && \
      remote_branch=$remote_assume
    [[ -z $remote_repo || $remote_repo == '.' ]] && remote_repo=origin

    # discriminate `crit', and fix `local_repo'
    crit=${local_repo%:*}
    local_repo=${local_repo##*:}

    [[ $crit == $local_repo ]] && crit=""

    cmd="git -C $local_repo fetch -puft $remote_repo -- \
$remote_branch:$local_branch"

    echo "[ .. ] Fetching repository: $local_repo"
    echo "[ == ] Running: $cmd"

    # stash and restore changes if we have `local_repo' checked out
    head_ref=$(git -C $local_repo rev-parse HEAD)

    if [[ "$(git -C $local_repo rev-parse \
               $local_branch 2>/dev/null)" == "$head_ref" ]]; then
      checked=true
    else
      checked=false
    fi

    if $checked; then
      ref=$(git -C $local_repo stash create \
                "Stashing update on $(date +'%Y%m%d-%w %I%M%p')")

      if [[ ! -z $ref ]]; then
        echo "[ WW ] $local_repo has $local_branch checked out, and with changes\
  , stashing them to ($ref)"

        git -C $local_repo restore -SW .
      fi
    fi

    # handle criteria:
    case $crit in
      'tag'|'tf'|'rtf')
        eval $cmd >& /tmp/.gitout
        cat /tmp/.gitout

        if grep -q '\[new tag\]' /tmp/.gitout; then
          echo "  -> on \`$local_repo' ($crit): new tag"
        else
          echo "  -> on \`$local_repo' ($crit): OK"
        fi
        ;;
      bf:*|rbf:*)
        eval $cmd
        _crit=$crit
        crit=${crit%:*}
        check_branch=${_crit#*:}

        [[ -z $check_branch ]] && check_branch=master

        post_cmd="git -C $local_repo merge-base --is-ancestor $check_branch $local_branch"

        echo "[ == ] Checking merge with: $post_cmd"

        if eval $post_cmd; then
          echo "  -> on \`$local_repo' ($crit): needs merge"
        else
          echo "  -> on \`$local_repo' ($crit): OK"
        fi ;;
      '') eval $cmd ;;
    esac

    # clean-up, otherwise some weird shit happens
    # removes index files from fetch, in case we had it checked out
    if $checked; then
      echo "[ .. ] \`$local_repo' had \`$local_branch' checked out, removing \
remnant files"
      git -C $local_repo checkout -f
    fi

    crit=""
    checked=false
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
