#!/usr/bin/bash

# By session:
#  $1: session type (X, tty, ...)
#  $2: wm

TYPE=$1
SESSION=$2

function session_msg {
  local msg=$1

  echo "[ $(date +%s) ] $msg" >> /tmp/session-msg
}
