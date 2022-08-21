#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       cron-like-jobs.sh"
		echo "Description: Lists cron-like jobs"
		exit 1
		;;
esac

if [[ ! -d /tmp/cron ]]
then
	echo "[ !! ] No cron directory was found"
	exit 1
fi

JOBS=$(find /tmp/cron -type f -not -name '*.sh')
if [[ ! -z $JOBS ]]
then
	while read job
	do
		echo "[ .. ] Cron job: $job"
		echo " ------------"
		cat $job
		echo " ------------
	"
	done <<< "$JOBS"
fi

SCRIPTS=$(find /tmp/cron -type f -name '*.sh')
if [[ ! -z $SCRIPTS ]]
then
	while read script
	do
		echo "[ .. ] Found cron jobs script: $script"
		echo " ------------"
		cat ${script%%.*}
		echo " ------------
	"
	done <<< "$SCRIPTS"
fi
