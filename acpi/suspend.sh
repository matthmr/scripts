#!/usr/bin/bash

case $1 in
  '--help'|'-h')
    echo "Usage:       suspend.sh"
    echo "Description: Suspends the system"
    exit 1;;
esac

if [[ $USER != root ]]; then
  echo "[ !! ] Need to be root"
  exit 1
fi

STATE=
SYSFS=

case ${0##*/} in
  'suspend.sh')
    STATE="mem" ;;
  'hibernate.sh')
    STATE="disk"
    echo 'shutdown' > /sys/power/disk ;;
  *)
    echo "[ !! ] What are you doing?"
    exit 1;;
esac

echo "[ OK ] Handing over to openrc"
sleep 1

echo "$STATE" > /sys/power/state
