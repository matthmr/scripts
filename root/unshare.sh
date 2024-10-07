#!/usr/bin/sh

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

if [[ $USER != 'root' ]]; then
  echo "[ !! ] Need to be root"
  exit 1
fi

exec unshare -n -- @UNSHARE_LOW_PRIV@ $@
