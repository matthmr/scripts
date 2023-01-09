#!/usr/bin/sh

OOD=false
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

  HEAD_CM=$(git -C $repo show HEAD~1 | getcm)
  MASTER_CM=$(git -C $repo show remotes/origin/HEAD | getcm)

  if [[ $HEAD_CM != $MASTER_CM ]]
  then
    OOD=true
    echo "[ !! ] \`${repo##*/}' is out-of-date"
  #else
    #echo "[ OK ] \`${repo##*/}' is updated"
  fi
done < $GITLOCAL

if $OOD
then
  echo "[ !! ] There are out-of-date repositories"
else
  echo "[ OK ] All repositories are up-to-date"
fi
