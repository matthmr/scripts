#!/usr/bin/bash

function usage {
  echo "Usage:       alarm.sh <time>"
  echo "Description: Waits for <time> seconds, then beeps an alarm to the tty"
}

case $1 in
  '-h'|'--help')
    usage
    exit 1;;
esac

SLEEP=sleep
SLEEPTIME=0.5

if [[ -z $1 ]]; then
  echo "[ WW ] Running dry alarm"
else
  TIME=$1
  echo "[ .. ] Sleeping"
  $SLEEP $TIME
fi

echo "[ OK ] Done. Press C-c to stop the alarm"

while :
do
  $SLEEP $SLEEPTIME
  printf "\a" > /dev/tty1
done
