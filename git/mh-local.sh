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

while read repo
do
  if [[ $repo =~ ^#.*$ || $repo =~ ^( \t)*$ ]]
  then
    continue
  fi

  repo_path=${repo/ */}
  repo_branch=${repo/* /}

  echo "[ .. ] mh-local.sh: fetching repo: $repo"

  git -C $repo_path fetch origin -- HEAD

  LOCAL_MASTER_CM=$(git -C  $repo_path show $repo_branch | getcm)
  REMOTE_MASTER_CM=$(git -C $repo_path show FETCH_HEAD   | getcm)

  if [[ $HEAD_CM != $MASTER_CM ]]
  then
    echo "[ !! ] \`${repo_path##*/}' is out-of-date"
    OOD+=" ${repo_path##*/}"
  #else
    #echo "[ OK ] \`${repo_path##*/}' is updated"
  fi
done < $GITLOCAL

if [[ ! -z $OOD ]]; then
  echo "[ !! ] These repositories need to be merged: $(echo $OOD | sed 's/ /\n- /g')"
else
  echo "[ OK ] All repositories are up-to-date"
fi

echo "[ OK ] mh-local.sh: Done"

exit 0
