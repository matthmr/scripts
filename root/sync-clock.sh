#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
  echo "[ !! ] Need to be root"
  exit 1
fi

case $1 in
  '-h'|'--help')
    echo "Usage:       sync-clock.sh"
    echo "Description: Update system clock with \`NTP' and \`chrony'"
    exit 1 ;;
esac

echo "[ .. ] Updating clock"

chronyd -d -q
