#!/usr/bin/sh

set -o noglob

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
PKG_FILE=@UPDATE_EFISTUB_TXT@

EFISTUB=usr/lib/systemd/boot/efi/linuxx64.efi.stub
SYSUSERS=usr/bin/systemd-sysusers
TMPFILES=usr/bin/systemd-tmpfiles
LIBS=('libsystemd-core' 'libsystemd-shared')

# Header
echo "[ HOOK ] Updating the EFI stub using systemd : $0"

if [[ ! -f $PMAN_DIR/efistub-lock ]]; then
	echo "[ !! ] No updates were found"
	exit 0
else
	# Backing up
	echo "[ .. ] Copying old stub"
	cp -v /$EFISTUB /$EFISTUB-old

	# Extract the stub plus any other bits of systemd
	echo "[ .. ] Extracting stub: $PMAN_DIR/efistub.tar.zstd "

  tar xf $PMAN_DIR/efistub.tar.zstd --zstd -C $PMAN_DIR

  cp -v $PMAN_DIR/$EFISTUB  /usr/lib/systemd/boot/efi/linuxx64.efi.stub
  cp -v $PMAN_DIR/$SYSUSERS /usr/bin/sysusers
  cp -v $PMAN_DIR/$TMPFILES /usr/bin/tmpfiles

  for lib in ${LIBS[@]}; do
    lib=$(find $PMAN_DIR -type f -name "*${lib}*")
    root_lib=$(find /usr/lib -type f -name "*${lib##*/}*")

    if [[ ! -z $root_lib ]]; then
      rm -v $root_lib
    fi
    cp -v $lib /usr/lib/${lib##*/}
  done

  # Applying
  echo "[ .. ] Making UKI"
  mkinitcpio

	# Remove lock
	echo "[ .. ] Removing lock"
	rm -v $PMAN_DIR/efistub-lock

	echo "[ .. ] Removing local lock"
	cp $PKG_FILE /tmp/efistub-pkgfile
	cat /tmp/efistub-pkgfile | cut -d' ' -f2 > $PKG_FILE
fi

echo "[ OK ] Done"
