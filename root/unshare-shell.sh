#!/usr/bin/sh

if [[ $USER != 'root' ]]; then
  echo "[ !! ] Need to be root"
  exit 1
fi

exec unshare -n -- @UNSHARE_SHELL_UNSHARE@
