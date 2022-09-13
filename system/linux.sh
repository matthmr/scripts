#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       linux.sh"
		echo "Description: Initial scripts to run on a linux system: user scripts"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1
		;;
esac

read -p "[ ?? ] Start scheduled system run-up? [Y/n] " ans

if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	sleep 5
	SHELL_PID=$$
	_ppid="$(ps -p $SHELL_PID -O ppid)"
	ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
	kill -KILL $ppid
	exit 1
fi

[[ -z $SUDO ]] && SUDO=doas

echo "[ .. ] Running user scripts"

echo "[ .. ] Updating Git-controlled packages"
/home/mh/Scripts/git/git.sh

echo "[ .. ] Updating source-controlled packages"
/home/mh/Scripts/pkg/ungoogled-chromium.sh

echo "[ .. ] Generating dmenu cache"
/home/mh/Scripts/dmenu-gencache.sh

echo "[ .. ] Syncing cron-like hooks"
/home/mh/Scripts/sync-cron-like.sh

echo "[ .. ] Preparing to run root scripts"
while ! $SUDO /home/mh/Scripts/system/linux-root.sh; do continue; done # always try to get the root password

echo "[ OK ] Done!"

echo "[ .. ] Running user-defined daemons"
/home/mh/Scripts/bin/emacsserver start
/home/mh/Scripts/tmp/copylog

echo "[ .. ] Finding hooks"
if [[ -d /home/mh/Hooks/linux.sh && -d /home/mh/Hooks/IRL/ ]]
then
	echo "[ OK ] Hooks found:
-----------------" 1>&2
	cat /home/mh/Hooks/linux.sh/*.hook /home/mh/Hooks/IRL/TODO
	echo "
----------------" 1>&2
else
	echo "[ !! ] No hooks found!" 1>&2
fi

if [[ -d /tmp/cron ]]
then
	echo "[ .. ] Found cron jobs. Handling their messages"
	files=$(find /tmp/cron/* -not -name '*.sh' | sed 's./tmp/cron/..g')
	while read file
	do
		cat "/tmp/cron/$file"
	done <<< "$files"
	sleep 5
else
	echo "[ .. ] No cron job was found; echoing their message just in case one got skipped"
	/home/mh/Scripts/list-all-cron-like-jobs.sh
	sleep 5
fi

SHELL_PID=$$
sleep 5
_ppid="$(ps -p $SHELL_PID -O ppid)"
ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
kill -KILL $ppid
exit 1

