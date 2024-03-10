#!/usr/bin/sh

awk '
  {
    minutes=int($1 / 60); hours=int(minutes / 60)
    if (hours < 10) { hours="0" hours}
    minutes_rem=minutes % 60
    if (minutes_rem < 10) { minutes_rem="0" minutes_rem}
    printf("%s%s", hours, minutes_rem)
  }' /proc/uptime
