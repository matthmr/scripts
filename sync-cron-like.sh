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

function found {
	echo "[ ** ] Found a hook with $1"
}

function script {
	if [[ ! -d /tmp/cron ]]
	then
		TMP=$(mktemp -d "/tmp/cron.XXX")
		chown -Rv mh:mh $TMP
		chmod -Rv a+w $TMP
		mv -v $TMP /tmp/cron
	fi
	FILE="$1"
	CONTENT="$2"
	echo "$CONTENT" > /tmp/cron/$FILE.sh
	chmod -v a+x /tmp/cron/$FILE.sh
}

DATE=$(date +%m%d)

case $DATE in
	??01)
		found "$DATE"
		write 'reddit-wallpaper' "Go find some more wallpapers"
		write 'wiki' "Commit to the wiki and journal repositories"
		write 'music' "Find more music!";;
	??10)
		found "$DATE (script)"
		write 'pacman' "Execute the \`~/Scripts/pacman/q.sh' command"
		script 'pacman' 'exec ~/Scripts/pacman/q.sh';;
	??20)
		found "$DATE"
		write 'browser-bookmarks' "Make a backup of browser bookmarks, if too big, then archive the backups";;
	0601|1201)
		found "$DATE"
		write 'backup' "Make a backup of important files, including the root and home partitions";;
	1231)
		found "$DATE"
		write 'clean-computer' "Clean the computer, it has been dirty for almost a year!";;
esac

echo "[ OK ] sync-cron-like.sh: Done"

exit 0
