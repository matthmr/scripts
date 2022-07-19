#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

case $1 in
	'-h'|'--help')
		echo "Usage:       hello-world.sh"
		echo "Description: Initial scripts to run on a linux system"
		exit 1
esac

echo "[ cd-ing to the \`~/Scripts' directory ]"
pushd /home/mh/Scripts

echo "[ Updating pacman's database ]"
pman -Sy || exit $?

echo "[ Updating artix's pacman's database ]"
pmanrc -Sy || exit $?

echo "[ Synchronizing clock ]"
./sync-clock.sh || exit $?

echo "[ Updating Git-controlled packages ]"
pkg/zsh-plugins.sh || exit $?

echo "[ Updating source-controlled packages ]"
pkg/ungoogled-chromium.sh || exit $?

echo "[ Generating dmenu cache ]"
./dmenu-gencache.sh || exit $?

echo "[ cd-ing back ]"
popd

echo "[ Sending user over to the journal ]"
nvim /home/mh/Wiki/Journal/index.md &

echo "[ Done! ]"
exit 0
