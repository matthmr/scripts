#!/usr/bin/env bash

case $1 in
	'-h'|'--help')
		echo "Usage:       git.sh"
		echo "Description: Update git-controlled packages"
		exit 1
esac

while read repo
do

	if [[ $repo =~ ^#.* ]]
	then
		echo "[ !! ] Ignoring \`${repo##*#}'"
		continue
	fi

	pushd $repo > /dev/null
	echo "[ .. ] pulling repository: $repo"
	git pull
	popd > /dev/null
done < /home/mh/Scripts/git/gitinclude.txt

echo "[ OK ] Done"
