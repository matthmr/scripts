#!/usr/bin/sh

if [[ $USER != 'root' ]]
then
	echo "[ !! ] Need to be root"
	exit 1
fi

echo "[ .. ] Running root scripts"

echo "[ .. ] Setting up \`tmp'"
TMP=$(mktemp -d "/tmp/pacman.XXX")

echo "[ .. ] Updating pacman's database"
/home/mh/.local/bin/pman -Syy # this also updates paru's

echo "[ .. ] Updating artix's pacman's database"
/home/mh/.local/bin/pmanrc -Syy

echo "[ .. ] Generating update file for pacman"
/home/mh/.local/bin/pman -Qu > $TMP/pacman-raw
/bin/sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/pacman-raw | awk '{print $1}' > $TMP/pacman

echo "[ .. ] Generating update file for paru"
/mnt/ssd/root/usr/bin/paru -Qu > $TMP/paru-raw
/bin/sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/paru-raw | awk '{print $1}' > $TMP/paru

echo "[ .. ] Generating update file for artix's pacman"
/home/mh/.local/bin/pmanrc -Qu > $TMP/pacman-artix-raw
/bin/sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' $TMP/pacman-artix-raw | awk '{print $1}' > $TMP/pacman-artix

echo "[ .. ] Setting persmissions for pacman-related files"
chown -Rv mh:mh $TMP
chmod -Rv a+w $TMP

echo "[ .. ] Synchronizing clock"
/home/mh/Scripts/sync-clock.sh

#echo "[ .. ] Synchronizing crontabs"
#/home/mh/Scripts/sync-cron.sh

echo "[ .. ] Moving tmp to a standardised location"
mv -v $TMP /tmp/pacman

echo "[ .. ] Setting update locks for pacman"
{
	grep -qwi linux /tmp/pacman/pacman
} && {
	echo "[ OK ] Found pacman lock"
	touch /tmp/pacman/lock-pacman
	chown -Rv mh:mh /tmp/pacman/lock-pacman
	chmod -Rv a+w /tmp/pacman/lock-pacman
} || {
	echo "[ !! ] No lock was found for pacman"
}

echo "[ .. ] Setting update locks for paru"
{
	grep -qi nvidia /tmp/pacman/paru
} && {
	echo "[ OK ] Found paru lock"
	touch /tmp/pacman/lock-paru
	chown -Rv mh:mh /tmp/pacman/lock-paru
	chmod -Rv a+w /tmp/pacman/lock-paru
} || {
	echo "[ !! ] No lock was found for paru"
}

echo "[ .. ] Setting update locks for artix's pacman"
{
	grep -Eiq '(^e[^2x]|udev|.*-openrc|lib(elogind|udev))' /tmp/pacman/pacman-artix
} && {
	echo "[ .. ] Found artix's pacman lock"
	touch /tmp/pacman/lock-pacman-artix
	/bin/grep -Ei '(^e[^2x]|udev|.*-openrc|lib(elogin|udev))' /tmp/pacman/pacman-artix \
		> /tmp/pacman/pacman-artix-update
} || {
	echo "[ !! ] No lock was found for artix"
}

echo "[ OK ] Done with root scripts!"

exit 0
