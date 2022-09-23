#!/usr/bin/sh

# kill `emacsserver' to prevent it from SIGSEGVing
emacsserver stop >& /dev/null
exec i3-msg exit
