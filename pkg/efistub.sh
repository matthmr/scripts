#!/usr/bin/bash

case "$1" in
  '-h'|'--help')
    echo "Usage:       efistub.sh"
    echo "Description: Updates the systemd-boot efistub"
  exit 1;;
esac

[[ -z $1 ]] && {
  echo "[ !! ] Missing temporary directory"
  exit 1
}

UPDATE=false

PACMAN=pacman
TARGET=systemd
ARCH=x86_64

CACHE=@EFISTUB_PACMAN_CACHE@
PKG_DIR=@EFISTUB_PKG_DIR@
PMAN_DIR=$1

VER_FILE=$PKG_DIR/efistub.txt
LCK_FILE=$PMAN_DIR/efistub-lock
PKG_FILE=$PMAN_DIR/efistub.tar.zstd

function do_update {
  echo "[ .. ] Downloading package"
  $PACMAN -Sddww $TARGET

  if [[ $? != 0 ]]; then
    echo "[ !! ] Aborting"
    exit 1
  fi
}

function touch_lock {
  if [[ ! -d $PMAN_DIR ]]; then
    echo "[ !! ] No pacman directory. Did you run system/linux.sh?"
    exit 1
  else
    touch $LCK_FILE
  fi
}

function pkg_copy {
  echo "[ .. ] Copying package cache"
  cp -v $CACHE/$TARGET-$VER-$ARCH.pkg.tar.zst $PKG_FILE

  if [[ $? -ne 0 ]]; then
    echo "[ WW ] Package cache was not found. Redownloading..."
    do_update
  fi
}

function query_ver {
  echo "[ .. ] Querying a new version of $TARGET"
  VER=$(pacman -Si $TARGET | awk -F: '/^Version/ {print $2}')
  VER=${VER# }
}

function mk_update {
  echo "[ !! ] Update available (version: $VER). Overwriting old version file"
  echo "L $VER" > $VER_FILE
}

function update_stat {
  if [[ -f $VER_FILE ]]; then
    if [[ $(awk '{print $1}' $VER_FILE) = 'L' ]]; then
      echo "[ WW ] Lock is set"
      touch_lock
      pkg_copy
      exit 0
    fi

    local VER_FILE_VER=$(cat $VER_FILE)

    if [[ "$VER" = "$VER_FILE_VER" ]]; then
      echo "[ OK ] Up-to-date"
      exit 0
    else
      # mismatch version && no lock is set
      echo "[ WW ] Out of date; no lock is set"
      UPDATE=true
    fi
  else
    echo "[ WW ] No version file. Creating one..."
    UPDATE=true
  fi
}

query_ver
update_stat

if $UPDATE; then
  do_update
  touch_lock
  mk_update
  pkg_copy
fi

echo "[ OK ] pkg/efistub.sh: Done"
exit 0
