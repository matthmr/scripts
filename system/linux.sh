#!/usr/bin/bash

XTERM=xterm
TIMEOUT=5

case $1 in
	'-h'|'--help')
		echo "Usage:       linux.sh"
		echo "Description: Initial scripts to run on a linux system: user scripts"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1
		;;
esac

#################### GUARD ####################
read -p "[ ?? ] Start scheduled system run-up? [Y/n] " ans

if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	sleep 1

  unset XINITSLEEP
  unset XINITSLEEPARGS
  exit 0
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

echo "[ .. ] Setting up \`tmp'"
TMP=$(mktemp -d "/tmp/pacman.XXX")

#################### UPDATE LOCAL PACKAGES ####################e

echo "[ .. ] Running user scripts"

echo "[ .. ] Updating Git-controlled packages"
/home/mh/Scripts/git/git.sh

echo "[ .. ] Updating locally Git-controlled packages"
/home/mh/Scripts/git/mh-local.sh update

echo "[ .. ] Updating big Git-controlled repositories"
/home/mh/Scripts/git/update-big-repo.sh

# TODO: make this a source list to something like `pacwrap' or `pkgm'
echo "[ .. ] Updating source-controlled packages"
/home/mh/Scripts/pkg/ungoogled-chromium.sh

#################### MISC ####################
echo "[ .. ] Generating dmenu cache"
/home/mh/Scripts/dmenu-gencache.sh

echo "[ .. ] Syncing cron-like hooks"
/home/mh/Scripts/sync-cron-like.sh

echo "[ .. ] Running user-defined daemons"
/home/mh/Scripts/system/usr-srv.sh

#################### ROOT / GLOBAL PACKAGES ####################
echo "[ .. ] Preparing to run root scripts"

# always try to get the root password
while ! $SUDO /home/mh/Scripts/system/linux-root.sh $TMP; do continue; done

# not a root script, but it needs to be run after those
/home/mh/Scripts/pkg/efistub.sh $TMP

#################### CRON / HOOKS ####################
echo "[ .. ] Finding hooks"
/home/mh/Scripts/hooks.sh

if [[ ! -d /tmp/cron ]]; then
	echo "[ .. ] No cron job was found; echoing their message just in case one got skipped"
	cat /home/mh/Scripts/job/jobs
	sleep $TIMEOUT
fi

echo "[ OK ] linux.sh: Done"
exit 0
