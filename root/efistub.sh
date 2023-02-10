#!/usr/bin/sh

case $1 in
  '--help'|'-h')
	  echo "Usage:       efistub.sh"
	  echo "Description: Runs the \`efistub' procedure"
	  exit 1;;
esac

if [[ $USER != root ]]; then
	echo "[ !! ] Need to be root"
	exit 1
fi

PMAN_DIR=/tmp/pacman
PKG_FILE=/home/mh/Scripts/pkg/efistub.txt
STUB=usr/lib/systemd/boot/efi/linuxx64.efi.stub

# Header
echo "[ HOOK ] Updating the EFI stub using systemd : $0"

if [[ ! -f $PMAN_DIR/lock-efistub ]]; then
	echo "[ !! ] No updates were found"
	exit 0
else
	# Backing up
	echo "[ .. ] Copying old stub"
	cp -v /$STUB /$STUB-old

	# Extract the stub
	echo "[ .. ] Extracting stub: $PMAN_DIR/efistub.tar.zstd "
	tar xf $PMAN_DIR/efistub.tar.zstd $STUB --zstd -O > /$STUB

	# Remove lock
	echo "[ .. ] Removing lock"
	rm -v $PMAN_DIR/lock-efistub
	echo "[ .. ] Removing local lock"
	cp $PKG_FILE /tmp/efistub-pkgfile
	cat /tmp/efistub-pkgfile | cut -d' ' -f2 > $PKG_FILE
	# mv -v /tmp/efistub-pkgfile $PKG_FILE

  # chown -v mh:mh $PKG_FILE
  # chmod -v 666 $PKG_FILE
fi

echo "[ OK ] Done"
