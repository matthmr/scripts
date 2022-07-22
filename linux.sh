#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       hello-world.sh"
		echo "Description: Initial scripts to run on a linux system: user scripts"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1
esac

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

echo "[ Extra human-driven commands: ]"
cat 1>&2 <<EOF
* nvim /home/mh/Wiki/Journal/index.md
EOF

exit 0
