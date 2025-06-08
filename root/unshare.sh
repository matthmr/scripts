#!/usr/bin/sh

SUDO=doas

case $1 in
  '--help'|'-h')
    echo "Usage:       unshare.sh [COMMAND]"
    echo "\
Description: Run COMMAND within an unshared network environment. If
             empty, spawn a shell instead. Pass INIT and the shell to
             execute a preamble command before spawning the shell"
    exit 0
    ;;
esac

args="$@"

cmd="su $USER"

if [[ -z $args ]]; then
  cmd+=" -s $SHELL"
else
  cmd+=" -c \"$args\""
fi

eval exec $SUDO unshare -n -- $cmd
