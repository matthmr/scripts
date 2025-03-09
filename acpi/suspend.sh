#!/usr/bin/bash

ACTION=''

case $1 in
  '--help'|'-h')
    echo "Usage:       suspend.sh (mem|disk)"
    echo "Description: Suspends (mem) or hibernates (disk) the system"
    exit 1;;
  'mem'|'disk') ACTION="$1" ;;
  *)
    echo "[ !! ] What are you doing?"
    exit 1;;
esac

if [[ $USER != root ]]; then
  echo "[ !! ] Need to be root"
  exit 1
fi

echo "[ OK ] Handing over to openrc"
sleep 1

echo $ACTION > /sys/power/state
