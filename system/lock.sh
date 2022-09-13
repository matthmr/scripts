#!/usr/bin/sh

USER_SHELL=zsh
COMMAND=$1

case $1 in
	'-h'|'--help')
		echo "Usage:       lock.sh"
		echo "Description: Lock the system ACPI reboot/shutdown to update packages"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1;;
esac

# carve out the command
PACMAN= ARTIX= PARU= CRON=
if [[ ${COMMAND:0:1} = 'p' ]] # pacman update
then
	PACMAN=y
	COMMAND=${COMMAND:1}
fi
if [[ ${COMMAND:0:1} = 'a' ]] # artix update
then
	ARTIX=y
	COMMAND=${COMMAND:1}
fi
if [[ ${COMMAND:0:1} = 'n' ]] # paru update
then
	PARU=y
	COMMAND=${COMMAND:1}
fi
if [[ ${COMMAND:0:1} = 'c' ]] # cron job update
then
	CRON=y
	COMMAND=${COMMAND:1}
fi
if [[ ${COMMAND:0:1} = 'd' ]] # cron job message update
then
	CRONMSG=y
	COMMAND=${COMMAND:1}
fi

case $COMMAND in
	'shutdown')
		COMMAND="openrc-shutdown -p now";;
	'reboot')
		COMMAND="openrc-shutdown -r now";;
		*)
		echo "[ !! ] Cannot run this script manually; exiting..."
		exit 1;;
esac

[[ -z $SUDO ]] && SUDO=doas

function _pacman {
	read -p "[ ?? ] Update packages? [Y/n] " ans

	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
		notify-send "Ignore lock" "lock was ignored for pacman"
		return 0
	fi

	read -p "[ ?? ] Manual review? [y/N] " ans
	[[ $ans = 'y' ]] && local MANUAL=y || local MANUAL=n

	if [[ $MANUAL = 'y' ]]
	then
		echo "[ .. ] Updating database for manual review"
		while ! $SUDO pman -Sy; do continue; done
		echo "[ .. ] Generating new pacman updatable package file"
		pman -Qu > /tmp/pacman/pacman-update-raw
		sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' /tmp/pacman/pacman-update-raw |\
			awk '{print $1}' > /tmp/pacman/pacman-update
		echo "[ .. ] Setting permissions"
		chown -Rv mh:mh /tmp/pacman/pacman-update /tmp/pacman/pacman-update-raw
		chmod -Rv a+w /tmp/pacman/pacman-update /tmp/pacman/pacman-update-raw
		echo "[ .. ] Listing updatable packages"
		/bin/less -R /tmp/pacman/pacman-update-raw
	fi

	read -p "[ ?? ] Check against wiki? [Y/n] " ans
	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
	else
		if [[ $MANUAL = 'y' ]]
		then
			#/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/pacman-update | /bin/less
			/home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/pacman-update | /bin/less
		else
			#/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/pacman | /bin/less
			/home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/pacman | /bin/less
		fi
	fi

	read -p "[ ?? ] Handle SSD packages? [Y/n] " ans
	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
	else # open a new shell, wait for it to die, then continue
		echo "[ OK ] Waiting for SSD packages to be handled"
		unset XINITSLEEP
		unset XINITSLEEPARGS
		$USER_SHELL
	fi

	echo "[ .. ] Updating system"
	$SUDO pman -Su

	echo "[ .. ] Removing lock"
	rm -v /tmp/pacman/lock-pacman
}

function _artix {
	read -p "[ ?? ] Update artix? [Y/n] " ans
	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
		notify-send "Ignore lock" "lock was ignored for artix"
		return 0
	else
		echo "[ .. ] Updating artix"
		if [[ -s /tmp/pacman/pacman-artix-update ]]
		then
			cat /tmp/pacman/pacman-artix-update | $SUDO xargs -o -I. /home/mh/.local/bin/pmanrc -S .
		else
			echo "[ !! ] Artix has no update available"
		fi
		echo "[ .. ] Removing lock"
		rm -v /tmp/pacman/lock-pacman-artix
	fi
}

function _paru {
	read -p "[ ?? ] Update AUR packages? [Y/n] " ans

	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
		notify-send "Ignore lock" "lock was ignored for paru"
		return 0
	fi

	read -p "[ ?? ] Manual review? [y/N] " ans
	[[ $ans = 'y' ]] && local MANUAL=y || local MANUAL=n

	if [[ $MANUAL = 'y' ]]
	then
		echo "[ .. ] Updating database for manual review"
		paru -Sy
		echo "[ .. ] Generating new pacman updatable package file"
		paru -Qu > /tmp/pacman/paru-update-raw
		sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' /tmp/pacman/paru-update-raw |\
			awk '{print $1}' > /tmp/pacman/paru-update
		echo "[ .. ] Setting permissions"
		chown -Rv mh:mh /tmp/pacman/paru-update /tmp/pacman/paru-update-raw
		chmod -Rv a+w /tmp/pacman/paru-update /tmp/pacman/paru-update-raw
		echo "[ .. ] Listing updatable packages"
		/bin/less -R /tmp/pacman/paru-update-raw
	fi

	read -p "[ ?? ] Check against wiki? [Y/n] " ans
	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
	else
		if [[ $MANUAL = 'y' ]]
		then
			#/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/paru-update | /bin/less
			/home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/paru-update | /bin/less
		else
			#/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/paru | /bin/less
			/home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/paru | /bin/less
		fi
	fi

	read -p "[ ?? ] Handle SSD packages? [Y/n] " ans
	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
	else # open a new shell, wait for it to die, then continue
		echo "[ OK ] Waiting for SSD packages to be handled"
		unset XINITSLEEP
		unset XINITSLEEPARGS
		$USER_SHELL
	fi

	echo "[ .. ] Updating system"
	paru -Su

	echo "[ .. ] Removing lock"
	rm -v /tmp/pacman/lock-paru
}

function _cron {
	local SCRIPTS="$(/bin/find /tmp/cron/ -type f -name '*.sh' 2>/dev/null)"
	read -p "[ ?? ] Cron-like script job found. Run it? [Y/n] " ans
	if [[ $ans = 'n' ]]
	then
		echo "[ !! ] Ignoring ... "
		notify-send "Ignore lock" "lock was ignored for cron"
		for file in $(echo $SCRIPTS|tr '\n' ' '); do rm -v $file ${file%%.sh}; done #remove the files
		return 0
	else
		while read file
		do
			echo "[ .. ] Executing $file"
			sleep 1
			sh $file
			rm -v $file ${file%%.sh} #remove the files as we execute them
		done <<< "$SCRIPTS"
	fi
}

function _cronmsg {
	local JOBS="$(/bin/find /tmp/cron/ -type f -not -name '*.sh' 2>/dev/null)"
	echo "[ .. ] Cron-like message job found"
	/home/mh/Scripts/cron-like-jobs.sh
	# open a shell do to the jobs, when closing, prompt for openrc hand-over
	unset XINITSLEEP
	unset XINITSLEEPARGS
	$USER_SHELL
	for file in $(echo $JOBS|tr '\n' ' '); do rm -v $file; done #remove the files
}

[[ ! -z $PACMAN ]]  && _pacman
[[ ! -z $ARTIX ]]   && _artix
[[ ! -z $PARU ]]    && _paru
[[ ! -z $CRON ]]    && _cron
[[ ! -z $CRONMSG ]] && _cronmsg

read -p "[ ?? ] Hand over to openrc? [Y/n] " ans
if [[ $ans = 'n' ]]
then
	echo "[ !! ] Ignoring ... "
	exit 1
else
	echo "[ OK ] Handing over to openrc"
	notify-send "ACPI event sent" "waiting to send ACPI event; press C-c to ignore it"
	sleep 5
	exec $SUDO $COMMAND
fi
