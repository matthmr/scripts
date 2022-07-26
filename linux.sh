#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       linux.sh"
		echo "Description: Initial scripts to run on a linux system: user scripts"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1
esac

read -p "[ ?? ] Start scheduled system run-up? [Y/n] " ans

if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	sleep 1
	exit 1
fi


[[ -z $SUDO ]] && SUDO=doas

echo "\$[ Running user scripts ... ]"

echo "[ cd-ing to the \`~/Scripts' directory ]"
pushd /home/mh/Scripts

echo "[ Updating Git-controlled packages ]"
./git/git.sh

echo "[ Updating source-controlled packages ]"
./pkg/ungoogled-chromium.sh

echo "[ Generating dmenu cache ]"
./dmenu-gencache.sh

echo "[ Preparing to run root scripts]"
$SUDO ./linux-root.sh

echo "[ cd-ing back ]"
popd

echo "[ Done! ]"

echo "[ Login command hooks... ]"
if [[ -d /home/mh/Hooks/linux.sh && /home/mh/Hooks/linux.sh/cmd.hook ]]
then
	echo "[ OK ] Found command hook:
-----------------" 1>&2
	sed 's/^/* /g' /home/mh/Hooks/linux.sh/cmd.hook
	echo "
----------------" 1>&2
else
	echo "[ !! ] No command hook found!" 1>&2
fi

echo "[ TODO hooks... ]"
if [[ -f /home/mh/TODO ]]
then
	echo "[ OK ] Found \`TODO':
-----------------" 1>&2
	sed 's/^/* /g' /home/mh/TODO
	echo "
----------------" 1>&2
else
	echo "[ !! ] No \`TODO' file found!" 1>&2
fi

exit 0
