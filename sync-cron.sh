#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       sync-lock.sh"
		echo "Description: Send locks to tmpfs for \`linux.sh'-like notifications"
		exit 1
		;;
esac

echo "[ Updating crontabs ]"
rc-service cronie start

if [[ $1 = '-l' ]]
then
	echo "[ Latching on... ]"
	exit 1
fi

echo "[ Sleeping... ]"
sleep 5

echo "[ Turning off cronie ]"
rc-service cronie stop
