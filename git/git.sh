#!/usr/bin/env bash

case $1 in
	'-h'|'--help')
		echo "Usage:       git.sh"
		echo "Description: Update git-controlled packages"
		echo "Variables:
	GIT: git-like command"
		exit 1
esac

[[ -z $GIT ]] && GIT=git
GITDIR=/home/mh/Git

echo "[ cd-ing to the \`~/Git' directory ]"
pushd $GITDIR

while read repo
do

	if [[ $repo =~ ^#.* ]]
	then
		echo "[ !! ] Ignoring \`${repo##*#}'"
		continue
	fi

	pushd $repo > /dev/null
	echo "[ Pulling repository: $repo ]"
	$GIT pull
	popd > /dev/null
done < /home/mh/Scripts/git/gitinclude.txt

echo "[ cd-ing back ]"
popd
