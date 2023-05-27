#!/usr/bin/sh

[[ ! -z $(pidof Xorg) ]] && clipmenud &
mpd &
