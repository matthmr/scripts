#!/usr/bin/sh

if [[ "$USER" != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

case $1 in
	'-h'|'--help')
		echo "Usage:       sync-clock.sh [-l : latch on]"
		echo "Description: Update system clock with \`NTP' and \`chrony'"
		exit 1
esac

echo "[ Updating clock ]"
rc-service chrony start

if [[ $1 = '-l' ]]
then
	echo "[ Latching on... ]"
	exit 1
fi

echo "[ Sleeping... ]"
# sleep 5
sleep 10

echo "[ Turning off chrony ]"
rc-service chrony stop
