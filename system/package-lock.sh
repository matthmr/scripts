#!/usr/bin/sh

USER_SHELL=zsh
COMMAND=$1

if [[ $COMMAND != 'shutdown' && $COMMAND != 'reboot' ]]
then
	echo "[ !! ] Cannot run this script manually; exiting..."
	exit 1
fi

case $COMMAND in
	'-h'|'--help')
		echo "Usage:       lock.sh"
		echo "Description: Lock the sytem ACPI reboot/shutdown to update packages"
		echo "Variables:
	SUDO: sudo-like command"
		exit 1;;
	'shutdown')
		COMMAND='openrc-shutdown -p now'
		;;
	'reboot')
		COMMAND='openrc-shutdown -r now'
		;;
esac

[[ -z $SUDO ]] && SUDO=doas

read -p "[ ?? ] Update packages? [Y/n] " ans

if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	notify-send "Ignore lock" "lock was ignored; handing over to openrc. Press C-c to ignore"
	sleep 5
	exec $SUDO $COMMAND
fi

read -p "[ ?? ] Manual review? [y/N] " ans

MANUAL=no
if [[ $ans = "y" ]]
then
	MANUAL=yes
fi

if [[ $MANUAL = 'yes' ]]
then
	echo "[ .. ] Updating database for manual review"
	while ! $SUDO pman -Sy
	do
		continue
	done

	echo "[ .. ] Generating new pacman updatable package file"
	pman -Qu > /tmp/pacman/pacman-update-raw
	sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' /tmp/pacman/pacman-update-raw |\
	awk '{print $1}' > /tmp/pacman/pacman-update
	echo "[ .. ] Setting permissions"
	chown -Rv mh:mh /tmp/pacman/pacman-update /tmp/pacman/pacman-update-raw
	chmod -Rv a+w /tmp/pacman/pacman-update /tmp/pacman/pacman-update-raw
fi

echo "[ .. ] Listing updatable packages"
if [[ $MANUAL = 'yes' ]]
then
	less -R /tmp/pacman/pacman-update-raw
else
	less -R /tmp/pacman/pacman-raw
fi

read -p "[ ?? ] Check against wiki? [Y/n] " ans
if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
else
	if [[ $MANUAL = 'yes' ]]
	then
		/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/pacman-update | less
	else
		/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/pacman | less
	fi
fi

read -p "[ ?? ] Handle SSD packages? [Y/n] " ans
if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
else
	echo "[ OK ] Waiting for SSD packages to be handled"
	# open a new shell, wait for it to die, then continue
	unset XINITSLEEP
	unset XINITSLEEPARGS
	$USER_SHELL
fi

echo "[ .. ] Updating system"
$SUDO pman -Su

echo "[ .. ] Removing lock"
rm -v /tmp/pacman/lock-pacman

# then do artix's
if [[ -f /tmp/pacman/lock-pacman-artix ]]
then
	read -p "[ ?? ] Update artix? [Y/n] " ans
	if [[ $ans = "n" ]]
	then
		echo "[ !! ] Ignoring ... "
	else

		echo "[ .. ] Updating artix"
		if [[ -s /tmp/pacman/pacman-artix-update ]]
		then
			cat /tmp/pacman/pacman-artix-update | $SUDO xargs -o -i . pmanrc -S .
		else
			echo "[ !! ] Artix has no update available"
		fi

		echo "[ .. ] Removing lock"
		rm -v /tmp/pacman/lock-pacman-artix
	fi
fi

read -p "[ ?? ] Hand over to openrc? [Y/n] " ans
if [[ $ans = "n" ]]
then
	echo "[ !! ] Ignoring ... "
	SHELL_PID=$$
	_ppid="$(ps -p $SHELL_PID -O ppid)"
	ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
	kill -KILL $ppid
fi

echo "[ OK ] Handing over to openrc"
notify-send "ACPI event sent" "waiting to send ACPI event"
sleep 5
exec $SUDO $COMMAND
SHELL_PID=$$
_ppid="$(ps -p $SHELL_PID -O ppid)"
ppid=$(printf "$_ppid" | awk '{n = $2} END {print n}')
kill -KILL $ppid

