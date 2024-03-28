#!/usr/bin/sh

TIMEOUT=2

for job in $@; do
  printf "[ ?? ] Schedl: Run \`$job'? [Y/n] "
  read ans

  if [[ ! -z $ans && $ans != 'y' ]]; then
    echo "[ !! ] Ignoring ... "
  else
    echo "[ .. ] Executing \`$job'. Press C-c to cancel..."
    sleep $TIMEOUT
    $job
  fi
done
