#!/usr/bin/sh

# SSL of jobs
JOBS=$1
TIMEOUT=3

for job in $JOBS; do
  printf "[ ?? ] Schedl: Run \`$job'? [Y/n] "
  read ans
  if [[ $ans = 'n' ]]; then
    echo "[ !! ] Ignoring ... "
  else
    echo "[ .. ] Executing \`$job'. Press C-c to cancel..."
    sleep $TIMEOUT
    $job
  fi
done
