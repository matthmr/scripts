#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       webserver.sh <IP:PORT>"
    echo "Description: Starts a quick webserver at <IP:localhost> with <PORT:8022>"
    echo "Options:
    <IP:HOST>: editor-like command"
    echo "Variables:
    SERVER: server to use
    SERVER_IP: ip command flag for <SERVER>
    SERVER_PORT: port command flag for <SERVER>"
    exit 1;;
esac

[[ -z $SERVER ]] && SERVER='webfsd -F'
[[ -z $SERVER_IP ]] && SERVER_IP='-i'
[[ -z $SERVER_PORT ]] && SERVER_PORT='-p'

if [[ -z $1 ]]; then
  IP=localhost
  PORT=8022
else
  OPT_IP=${1%%:*}
  if [[ $OPT_IP == $1 ]]; then
    IP=$1
  else
    IP=$OPT_IP
    PORT=${1##*:}
  fi
fi

echo "[ .. ] Starting server: $SERVER $SERVER_IP $IP $SERVER_PORT $PORT"
$SERVER $SERVER_IP $IP $SERVER_PORT $PORT
