#!/usr/bin/sh

case $1 in
  '-h'|'--help')
    echo "Usage:       mh-local.sh"
    echo "Description: Update locally git-controlled packages"
    exit 1
esac

OOD=''
GITLOCAL=/home/mh/Scripts/git/mh-local.txt

function getcm {
  cat /dev/stdin | head -n1 | cut -d' ' -f2
}

function update_repo {
  while read repo
  do
    if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]
    then
      continue
    fi

    repo_path=${repo/ */}
    repo_branch=${repo/* /}

    echo "[ .. ] mh-local.sh: fetching repo: ${repo_path} @${repo_branch}"

    git -C $repo_path fetch origin -- $repo_branch
  done < $GITLOCAL
}

function check_ood {
  while read repo
  do
    if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]
    then
      continue
    fi

    repo_path=${repo/ */}
    repo_branch=${repo/* /}
    repo_name=${repo_path##*/}

    echo "[ .. ] checking $repo_name @$repo_branch..."

    LOCAL_MASTER_CM=$(git -C  $repo_path show $repo_branch | getcm)
    REMOTE_MASTER_CM=$(git -C $repo_path show FETCH_HEAD   | getcm)

    if [[ $LOCAL_MASTER_CM != $REMOTE_MASTER_CM ]]
    then
      echo "[ !! ] $repo_name is out-of-date"
      OOD+=" $repo_name"
    fi
  done < $GITLOCAL
}

if [[ $1 = 'update' ]]; then
  update_repo
fi

check_ood

if [[ ! -z $OOD ]]; then
  echo "[ !! ] These repositories need to be merged:
$(echo $OOD | sed -e 's/ /\n- /g' -e 's/^/- /g')"
else
  echo "[ OK ] All repositories are up-to-date"
fi

echo "[ OK ] mh-local.sh: Done"

exit 0
