#!/usr/bin/sh

# Script that runs as root and de-escalate privileges to run a command as the
# default user

cmdline_flag='-c'
args="$@"

# start a shell instead
if [[ -z $args ]]; then
  cmdline_flag='-s'
  args=@UNSHARE_LOW_PRIV_SHELL@
fi

echo "[ .. ] SU'ing into unprivileged user"
eval exec su @UNSHARE_LOW_PRIV_USER@ $cmdline_flag \"$args\"
