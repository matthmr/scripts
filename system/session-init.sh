#!/usr/bin/bash

# By session:
#  $1: session type (X, tty, ...)
#  $2: wm

TYPE=$1
SESSION=$2
XTERM=urxvt

function session_msg {
  local msg=$1

  echo "[ $(date +%s) ] $msg" >> /tmp/session-msg
}

#### Validation

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
       } ;;
  'tty') function validate_session() {
           return 0
         } ;;
esac

validate_session

#### Attaching/Messaging

if [[ ! -f /tmp/session-lock ]]; then
  sleep 1

  touch /tmp/session-lock

  if ! tmux has-session; then
    # quit tmux before the messages could've been displayed: ignore
    if [[ $SESSION == 'tmux' ]]; then
      exit 0
    fi

    tmux new-session -d -s 'tmux'
  fi

  # attach with `tmuxa' (tmuxa also switches, we don't want that)
  if [[ -z $(tmux list-clients -F "#{session_attached}") ]]; then
    tmuxa $([[ $TYPE == 'x' ]] && echo '-x')
  fi

  # tmux display-popup -T 'note' \
  #      "cat /tmp/session-msg" >&/dev/null
fi
