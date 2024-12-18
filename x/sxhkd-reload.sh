#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       sxhkd-reload.sh"
		echo "Description: Reload the \`sxhkd' hotkey deamon"
		exit 1
		;;
esac

INTERVAL=2
NOTIFY=herbec
PID=$(pidof sxhkd)

if [[ -z $PID ]]; then
  exit 1
else
  kill -TERM $PID
  sleep $INTERVAL
  $NOTIFY "sxhkd" "reloaded daemon" &
  sxhkd -a 'bracketleft' < /dev/null >& /dev/null &
  exit 0
fi
