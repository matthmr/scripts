#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       cron-lock.sh"
		echo "Description: Lock cron updates"
		exit 1
		;;
esac

FILE="$1"
CONTENT="$2"

if [[ -z $FILE || -z $CONTENT ]]
then
	exit 1
fi

if [[ ! -d /tmp/cron ]]
then
	TMP=$(mktemp -d "/tmp/cron.XXX")
	chown -Rv mh:mh $TMP
	chmod -Rv a+w $TMP
	mv -v $TMP /tmp/cron
fi

echo "$CONTENT" > /tmp/cron/$FILE
