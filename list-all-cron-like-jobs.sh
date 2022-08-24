#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       list-all-cron-like-jobs.sh"
		echo "Description: Lists ALL cron-like jobs, so that it's easy to assure if one is missing; TODO: substitute this with a C program"
		exit 1
		;;
esac

cat /home/mh/Scripts/sync-cron-like.sh | awk '
BEGIN { line = 0 }
/^case \$DATE in/ { line = NR }
NR >= line && line != 0 { print }'
