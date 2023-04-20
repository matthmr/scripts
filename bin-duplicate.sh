#!/usr/bin/sh

case $1 in
  '-h'|'--help')
    echo "Usage:       bin-duplicate.sh"
    echo "Description: Find duplicated binaries on all system prefixes"
    exit 1;;
esac

/usr/bin/ls -1 /usr/bin > /tmp/root-bin
/usr/bin/ls -1 /mnt/ssd/root/usr/bin > /tmp/ssd-bin

/home/mh/Scripts/diff/diff.sh - /tmp/ssd-bin /tmp/root-bin | grep '^ '
