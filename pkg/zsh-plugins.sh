#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       zsh-plugins.sh"
		echo "Description: Updates git-controlled \`zsh' plugins"
		echo "Variables:
	GIT : git-like command"
		exit 1
esac

[[ -z $GIT ]] && GIT=git

echo '[ INFO ] cd /home/mh/Git/zsh-autosuggestions/'
cd /home/mh/Git/zsh-autosuggestions/
$GIT pull
echo '[ INFO ] cd /home/mh/Git/zsh-syntax-highlighting/'
cd /home/mh/Git/zsh-syntax-highlighting/
$GIT pull
