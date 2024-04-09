#!/usr/bin/bash

# By session:
#  $1: session type (X, tty, ...)
#  $2: wm

TYPE=$1
SESSION=$2

XTERM=urxvt

case $TYPE in
  'x') function validate_session() {
         local tries=5
         local timeout=5

         # wait for X to start, if it hasn't yet, keep waiting...
         while :; do
           sleep $timeout
           pidof $SESSION > /dev/null && break
           if [[ $tries == '0' ]]; then
             exit 1
           fi

           tries=$((tries-1))
         done
       }
       ;;
  *) function validate_session() {
       return 0
     }
     ;;
esac

touch /tmp/session-msg

validate_session

@SESSION_MSG_SESSION_INIT@ $1 $2

if [[ -s /tmp/session-msg ]]; then
  (sleep 1 && \
     {
       if ! tmux has-session; then
         tmux new-session -d
       fi

       # attach with `tmuxa' (tmuxa also switches, we don't want that)
       if [[ -z $(tmux list-clients -F "#{session_attached}") ]]; then
         (tmuxa $([[ $TYPE == 'x' ]] && echo '-x') '' &)
       fi

       sleep 1

       tmux display-popup \
            -T 'note' \
            "cat /tmp/session-msg" >/dev/null 2>/dev/null

       cp /tmp/session-msg /tmp/session-msg.txt
       printf '' > /tmp/session-msg
     } &
  )
fi
