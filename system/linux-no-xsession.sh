#!/usr/bin/sh

TIMEOUT=5

case $1 in
	'-h'|'--help')
		echo "Usage:       linux-no-xsession.sh"
		echo "Description: Initial scripts to run on a linux system: user scripts; no \`xsession'"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1
		;;
esac

read -p "[ ?? ] Start scheduled system run-up? [Y/n] " ans

if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	sleep $TIMEOUT
	SHELL_PID=$$
	_ppid="$(ps -p $SHELL_PID -O ppid)"
	ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
	kill -KILL $ppid
	exit 1
else
  # wait for a local ip address to be bound to this machine, otherwise we can't
  # run inet-like scripts
  echo "[ .. ] Waiting for a local ip address"
  INTERFACE=eth0
  while :; do
    if ! ip addr show $INTERFACE | grep -q '192\.168'; then
      echo "[ !! ] Got no local ip address, waiting \`$TIMEOUT's"
      sleep $TIMEOUT
      continue
    else
      echo "[ OK ] Got local ip assigned"
      break
    fi
  done
fi

[[ -z $SUDO ]] && SUDO=doas

echo "[ .. ] Running user scripts"

# See (20220916)
echo "[ .. ] Updating source-controlled packages"
/home/mh/Scripts/pkg/ungoogled-chromium.sh

echo "[ .. ] Generating dmenu cache"
/home/mh/Scripts/dmenu-gencache.sh

echo "[ .. ] Syncing cron-like hooks"
/home/mh/Scripts/sync-cron-like.sh

echo "[ .. ] Preparing to run root scripts"
while ! $SUDO /home/mh/Scripts/system/linux-root-no-xsession.sh; do continue; done # always try to get the root password

echo "[ OK ] Done!"

if [[ -d /tmp/cron ]]
then
	echo "[ .. ] Found cron jobs. Handling their messages"
	files=$(find /tmp/cron/* -not -name '*.sh' | sed 's./tmp/cron/..g')
	while read file
	do
		cat "/tmp/cron/$file"
	done <<< "$files"
	sleep $TIMEOUT
else
	echo "[ .. ] No cron job was found; echoing their message just in case one got skipped"
	/home/mh/Scripts/list-all-cron-like-jobs.sh
	sleep $TIMEOUT
fi

SHELL_PID=$$
sleep $TIMEOUT
_ppid="$(ps -p $SHELL_PID -O ppid)"
ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
kill -KILL $ppid
exit 1
