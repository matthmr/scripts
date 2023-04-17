#!/usr/bin/sh

function start_srv {
  echo "[ .. ] Starting $1"
  /home/mh/Run/$1 start
}

function start_prog {
  echo "[ .. ] Starting $1"
  $1 &
}

start_srv mpd

[[ ! -z $(pidof Xorg) ]] && clipmenud &
