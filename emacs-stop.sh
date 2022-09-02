#!/bin/bash
# Copyright 2008-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2 or later

# Lisp expression to be evaluated when stopping Emacs.
# Any additional commands should preferably be added to kill-emacs-hook.
EMACS_LISP_EXPR="(kill-emacs)"

su "${USER}" \
    -c "${EMACSCLIENT} ${EMACSCLIENT_OPTS} --eval \"${EMACS_LISP_EXPR}\"" \
    </dev/null &>/dev/null &
pid=$!

# Wait for emacsclient
for (( t=${EMACS_TIMEOUT:-30}; t > 0; t-- )); do
    sleep 1
    kill -0 ${pid} 2>/dev/null || exit 0
done

echo "${0##*/}: timeout waiting for emacsclient" >&2
kill ${pid} 2>/dev/null

# exit 0: openrc-run shall continue and (forcibly) kill the emacs process
# exit 1: openrc-run shall exit with an error
exit 0
