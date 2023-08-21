#!/usr/bin/sh

PARU_TRIGGER='openrc'
PACMAN_TRIGGER='linux'

if [[ $USER != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

[[ -z $1 ]] && {
  echo "[ !! ] Missing temporary directory"
  exit 1
} || {
  TMP=$1
}

#################### ROOT SCRIPTS ####################
echo "[ .. ] Running root scripts"

# See (20221105)
# echo "[ .. ] Running temporary scripts"
# /home/p/scripts/tmp/copylog

echo "[ .. ] Synchronizing clock"
# update 20220910: increase the time in `sync-clock' to 10 seconds and therefore send it to the background
/home/p/scripts/root/sync-clock.sh &

# See (20230318)
echo "[ .. ] Starting services"
/home/p/scripts/system/srv.sh

#################### GLOBAL PACKAGES ####################
echo "[ .. ] Updating pacman's database"
pacman -Syy # this also updates paru's
pacman -Fyy # this also updates paru's

echo "[ .. ] Generating update file for pacman"
pacman -Qu > $TMP/pacman-raw
sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/pacman-raw |\
  awk '{print $1}' > $TMP/pacman

echo "[ .. ] Generating update file for paru"
/mnt/ssd/root/usr/bin/paru -Qu > $TMP/paru-raw
sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/paru-raw |\
  awk '{print $1}' > $TMP/paru

echo "[ .. ] Setting persmissions for pacman-related files"
chown -Rv mh:mh $TMP
chmod -Rv a+w $TMP

#################### PACKAGE LOCKS ####################
echo "[ .. ] Setting update locks for pacman"
{
	grep -qwi "$PACMAN_TRIGGER" /tmp/pacman/pacman
} && {
	echo "[ OK ] Found pacman lock"
	touch /tmp/pacman/pacman-lock
	chown -Rv mh:mh /tmp/pacman/pacman-lock
	chmod -Rv a+w /tmp/pacman/pacman-lock
} || {
	echo "[ !! ] No lock was found for pacman"
}

echo "[ .. ] Setting update locks for paru"
{
	grep -qi "$PARU_TRIGGER" /tmp/pacman/paru
} && {
	echo "[ OK ] Found paru lock"
	touch /tmp/pacman/paru-lock
	chown -Rv mh:mh /tmp/pacman/paru-lock
	chmod -Rv a+w /tmp/pacman/paru-lock
} || {
	echo "[ !! ] No lock was found for paru"
}

echo "[ OK ] linux-root.sh: Done"
