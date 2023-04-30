#!/usr/bin/bash

XTERM=xterm
TERMCMD=-e
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

if [[ $1 == '-x' ]]; then
  function kill_term {
    local shell_pid=$1
    local _ppid="$(ps -p $SHELL_PID -O ppid)"
    ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
    kill -KILL $ppid
    exit 1
  }
else
  function kill_term {
    exit 1 # stub
  }
fi

#################### GUARD ####################
read -p "[ ?? ] Start scheduled system run-up? [Y/n] " ans

if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	sleep $TIMEOUT
  kill_term $$
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
/home/mh/Scripts/pkg/efistub.sh $TMP

# echo "[ .. ] Updating pacwrap packages"
# pacwrap update

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

if [[ $1 == '-x' ]]; then
  # wait for the user to close the window
  echo "[ .. ] Listing out-of-date packages"
  $XTERM $TERMCMD less /tmp/pacman/pacman-raw /tmp/pacman/paru-raw # /tmp/pacman/pacman-artix-raw
fi

#################### CRON / HOOKS ####################
echo "[ .. ] Finding hooks"
/home/mh/Scripts/hooks.sh

if [[ ! -d /tmp/cron ]]; then
	echo "[ .. ] No cron job was found; echoing their message just in case one got skipped"
	cat /home/mh/Scripts/job/jobs
	sleep $TIMEOUT
fi

echo "[ OK ] linux.sh: Done"
