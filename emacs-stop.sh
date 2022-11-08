#!/bin/bash

# 20220905 update: changed to make it more verbose

# Lisp expression to be evaluated when stopping Emacs.
# Any additional commands should preferably be added to kill-emacs-hook.
EMACS_LISP_EXPR="(kill-emacs)"

echo "[emacs-stop.sh] Executing command ${EMACSCLIENT} ${EMACSCLIENT_OPTS} --eval \"${EMACS_LISP_EXPR}\""

su "${USER}" \
    -c "${EMACSCLIENT} ${EMACSCLIENT_OPTS} --eval \"${EMACS_LISP_EXPR}\"" \
    </dev/null &>/dev/null &
pid=$!

echo "[emacs-stop.sh] got pid of \`$pid'"

# Wait for emacsclient
for (( t=${EMACS_TIMEOUT:-10}; t > 0; t-- )); do
    echo "[emacs-stop.sh]::for(t) = $t"
    sleep 1

    {
	kill -0 ${pid} 2>/dev/null
    } || {
	EMACS_DAEMON_PID=$(cat /run/user/$UID/emacs/emacs.pid)
	echo "[emacs-stop.sh] got deamon pid of \`${EMACS_DAEMON_PID}'. Removing /run/user/$UID/emacs/emacs.pid"
	rm /run/user/$UID/emacs/emacs.pid
	{
	    kill $EMACS_DAEMON_PID
	} && {
	    echo "[emacs-stop.sh] Succefully stopped the emacs deamon"
	} || {
	    echo "[emacs-stop.sh] Could not stop the emacs deamon"
	}
	exit 0
    }
done

echo "${0##*/}: timeout waiting for emacsclient" >&2
kill ${pid} 2>/dev/null

# exit 0: openrc-run shall continue and (forcibly) kill the emacs process
# exit 1: openrc-run shall exit with an error
exit 0
