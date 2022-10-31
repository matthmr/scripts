#!/usr/bin/sh

case "$1" in
	'-h'|'--help')
		echo "Usage:       efistub.sh"
		echo "Description: Updates the systemd-boot efistub"
	exit 1
	;;
esac

if [[ $USER != root ]]; then
	echo "[ !! ] Need to be root"
	exit 1
fi

PACMAN=pacman
CACHE=/mnt/ssd/pacman/cache
PKG_DIR=/home/mh/Scripts/pkg

VER_FILE=$PKG_DIR/efistub.txt
LCK_FILE=$PKG_DIR/efistub.lock
PKG_FILE=$PKG_DIR/efistub.tar.zstd

UPDATE=false

echo "[ .. ] Querying a new version of systemd"
VER=$(pacman -Si systemd | awk -F: '/^Version/ {print $2}')
VER=${VER# }

if [[ -f $VER_FILE ]]; then
	if echo "$VER" | diff - $VER_FILE >& /dev/null; then
		echo "[ OK ] Up-to-date"
	else
		echo "[ !! ] Update available (version: $VER). Overwriting old version file"
		echo "$VER" > $VER_FILE
		UPDATE=true
	fi
else
	echo "[ WW ] No version file. Creating one..."
	UPDATE=true
fi

if $UPDATE; then
  echo "[ .. ] Setting up lock"
  touch $LCK_FILE

	echo "[ .. ] Downloading package"
	$PACMAN -Sddww systemd

	if [[ $? != 0 ]]; then
		echo "[ !! ] Aborting"
		exit 1
	fi

	echo "[ .. ] Extracting cache"
	cp -v $CACHE/systemd-$VER-x86_64.pkg.tar.zst \
		$PKG_FILE
fi
