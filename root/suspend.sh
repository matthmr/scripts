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

export OP

STATE=
SYSFS=

case ${0##*/} in
  'suspend.sh')
    OP="suspend"
    STATE="mem"
    SYSFS="/sys/power/state";;
  'hibernate.sh')
    OP="hibernate"
    STATE="disk"
    SYSFS="/sys/power/state";;
  *)
    echo "[ !! ] What are you doing?"
    exit 1;;
esac

source /home/mh/Scripts/root/suspend/pre
echo "$STATE" > "$SYSFS"
source /home/mh/Scripts/root/suspend/post
