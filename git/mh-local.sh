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

  echo "[ .. ] mh-local.sh: repo: $repo"

  # behind HEAD there must the `master' branch:
  #    . (HEAD -> mh-local)
  #    |
  #    . (master)
  HEAD_CM=$(git -C $repo show HEAD~1 | getcm)
  MASTER_CM=$(git -C $repo show remotes/origin/HEAD | getcm)

  if [[ $HEAD_CM != $MASTER_CM ]]
  then
    echo "[ !! ] \`${repo##*/}' is out-of-date"
    OOD+=" ${repo##*/}"
  #else
    #echo "[ OK ] \`${repo##*/}' is updated"
  fi
done < $GITLOCAL

if [[ ! -z $OOD ]]; then
  echo "[ !! ] These repositories need to be merged: $(echo $OOD | sed 's/ /\n- /g')"
else
  echo "[ OK ] All repositories are up-to-date"
fi

echo "[ OK ] mh-local.sh: Done"

exit 0
