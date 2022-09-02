#!/bin/bash
# Copyright 2008-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2 or later

# Save output in a temporary file and display in case of error
logfile=$(mktemp ${TMPDIR:-/tmp}/emacs.log.XXXXXX)
trap "rm -f '${logfile}'" EXIT

# Start Emacs with a login shell wrapper to read the user's profile
exec -l "${SHELL}" -c "exec \"${EMACS}\" $*" </dev/null &>"${logfile}" &
pid=$!

# Wait for Emacs daemon to detach
for (( t=${EMACS_TIMEOUT:-30}; t > 0; t-- )); do
    sleep 1
    if ! kill -0 ${pid} 2>/dev/null; then
        wait ${pid}		# get exit status
        status=$?
        [[ ${status} -ne 0 || -n ${EMACS_DEBUG} ]] && cat "${logfile}"
        exit ${status}
    fi
done

cat "${logfile}"
echo "${0##*/}: timeout waiting for ${EMACS} to detach" >&2
kill ${pid} $(pgrep -P ${pid}) 2>/dev/null
exit 1
