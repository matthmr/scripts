#!/usr/bin/sh

if [[ $USER != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

echo "[ .. ] Running root scripts"

echo "[ .. ] Synchronizing clock"
/home/mh/Scripts/sync-clock.sh &

echo "[ OK ] Done with root scripts!"

exit 0
