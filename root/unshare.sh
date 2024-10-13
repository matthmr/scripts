#!/usr/bin/sh

SUDO=doas

case $1 in
  '--help'|'-h')
    echo "Usage:       unshare.sh [COMMAND]"
    echo "\
Description: Run COMMAND within an unshared network environment. If
             empty, spawn a shell instead. Pass LOGINCMD and the shell to
             execute a preamble command before spawning the shell"
    exit 0
    ;;
esac

args="$@"

cmd="su $USER"

if [[ -z $args ]]; then
  cmd+=" -c \"$SHELL; exit 0\""
else
  cmd+=" -c \"$args; exit 0\""
fi

eval exec $SUDO unshare -n -- $cmd
