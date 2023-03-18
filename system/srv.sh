#!/usr/bin/sh

function start_srv {
  echo "[ .. ] Starting $1"
  /home/mh/Run/$1 start
}

start_srv mpd
start_srv clipmenud
