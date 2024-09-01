#!/usr/bin/sh

job=$1
timeout=2

echo -n "[ ?? ] Run \`$job'? [Y/n] "
read ans </dev/tty

if [[ ! -z $ans && $ans != 'y' ]]; then
  echo "[ !! ] Ignoring ..."
else
  # don't send SIGINT to PPID (the parent shell running `schedl-init.sh')
  trap 'exit 0' SIGINT

  echo "[ .. ] Executing \`$job'. Press C-c to cancel..."
  sleep $timeout
  $job </dev/tty

  wait $!
fi
