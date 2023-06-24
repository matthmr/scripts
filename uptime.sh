#!/usr/bin/sh

_UPTIME=$(cut -d. -f1 /proc/uptime)
_MIN=$(($_UPTIME / 60))
_HOUR=$(($_MIN / 60))
_MIN=$(($_MIN % 60))
[[ $_HOUR =~ ^[0-9]$ ]] && _HOUR="0$_HOUR"
[[ $_MIN =~ ^[0-9]$ ]] && _MIN="0$_MIN"
UPTIME="$_HOUR$_MIN"

echo "$UPTIME"
