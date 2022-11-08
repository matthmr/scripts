#!/bin/bash

# 20220905 update: changed to make it more verbose

# Save output in a temporary file and display in case of error
logfile=$(mktemp ${TMPDIR:-/tmp}/emacs.log.XXXXXX)
echo "[emacs-wrapper.sh] Logging to $logfile.."
trap "rm -f '${logfile}'" EXIT

# Start Emacs with a login shell wrapper to read the user's profile
exec -l "${SHELL}" -c "exec \"${EMACS}\" $*" </dev/null &>"${logfile}" &
pid=$!

echo "[emacs-wrapper.sh] got pid of \`$pid'"

# Wait for Emacs daemon to detach
for (( t=${EMACS_TIMEOUT:-10}; t > 0; t-- )); do
    echo "[emacs-wrapper.sh]::for(t) = $t"
    sleep 1
    if ! kill -0 ${pid} 2>/dev/null; then
        wait ${pid}		# get exit status
        status=$?
        [[ ${status} -ne 0 || -n ${EMACS_DEBUG} ]] && cat "${logfile}"
	# write the pid
	EMACS_DAEMON_PID=$(${EMACSCLIENT} ${EMACSCLIENT_OPTS} -e '(emacs-pid)')
	{
	    [[ -z $EMACS_DAEMON_PID ]]
	} && {
	    echo "[emacs-wrapper.sh] got no deamon pid"
	    exit ${status}
	} || {
	    echo "[emacs-wrapper.sh] got deamon pid of \`${EMACS_DAEMON_PID}'. Saving to /run/user/$UID/emacs/emacs.pid"
	    echo ${EMACS_DAEMON_PID} > /run/user/$UID/emacs/emacs.pid
	    exit ${status}
	}
    fi
done

cat "${logfile}"
echo "${0##*/}: timeout waiting for ${EMACS} to detach" >&2
kill ${pid} $(pgrep -P ${pid}) 2>/dev/null
exit 1
