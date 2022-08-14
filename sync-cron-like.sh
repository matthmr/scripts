#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       sync-cron-like.sh"
		echo "Description: Send locks to tmpfs for \`linux.sh'-like notifications"
		exit 1
		;;
esac

function write {
	if [[ ! -d /tmp/cron ]]
	then
		TMP=$(mktemp -d "/tmp/cron.XXX")
		chown -Rv mh:mh $TMP
		chmod -Rv a+w $TMP
		mv -v $TMP /tmp/cron
	fi
	FILE="$1"
	CONTENT="$2"
	echo "$CONTENT" > /tmp/cron/$FILE
}

DATE=$(date +%m%d)

case $DATE in
	**01) echo "[ ** ] Found a hook with $DATE"
			write 'reddit-wallpaper' "Go find some more wallpapers"
			write 'wiki' "Commit to the wiki and journal repositories";;
	0601|1201) echo "[ ** ] Found a hook with $DATE"
			write 'backup' "Make a backup of important files, including the root and home partitions";;
esac
