#!/usr/bin/env bash

case $1 in
	'-h'|'--help')
		echo "Usage:       gitupdate.sh"
		echo "Description: Update \`git.sh' packages"
		echo "Variables:
	EDITOR: text editor to use if reviewing repositories"
		exit 1
esac

pushd /home/mh/Git >/dev/null
REPOS=$(find * -maxdepth 0 -type d -regex '[a-z0-9-_\.]' | tr ' ' '\n')
EDITOR=nvim
popd >/dev/null

read -p "[ ?? ] Review repositories? [y/N] " ans
if [[ $ans == 'y' ]]
then
	pushd /home/mh/Scripts/git >/dev/null
	{
		echo "$REPOS" | $EDITOR -
	} || {
		echo "[ !! ] Action aborted!" 1>&2
		popd >/dev/null
		exit 1
	} && {
		echo "[ OK ] Saved!"
		exit 0
		popd >/dev/null
	}
else
	echo "$REPOS" > gitinclude.txt && echo "[ OK ] Saved!"
fi

popd >/dev/null
