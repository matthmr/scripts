#!/usr/bin/sh

echo "[ .. ] Setting LO up"
sleep 3
ip link set lo up

echo "[ .. ] SU'ing into unprivileged user"
exec su mh --shell=/usr/bin/zsh
