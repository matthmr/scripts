#!/usr/bin/sh

# kill the main `xsetroot-statusbar' process, then kill the dangling `sleep' process
XSETROOT_STATUSBAR_PID=$(pgrep -f "xsetroot-statusbar$")

if [[ -z $XSETROOT_STATUSBAR_PID ]]; then
		exit 0
else
		SLEEP_PID=$(cat /proc/$XSETROOT_STATUSBAR_PID/task/$XSETROOT_STATUSBAR_PID/children)
fi

# actually kill both processes
kill -KILL $XSETROOT_STATUSBAR_PID
kill -KILL $SLEEP_PID
