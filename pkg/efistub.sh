#!/usr/bin/bash

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
PMAN_DIR=/tmp/pacman

VER_FILE=$PKG_DIR/efistub.txt
LCK_FILE=$PMAN_DIR/lock-efistub
PKG_FILE=$PMAN_DIR/efistub.tar.zstd

function touch_lock {
  if [[ ! -d $PMAN_DIR ]]; then
    echo "[ !! ] No pacman directory. Did you run system/linux.sh?"
    exit 1
  else
    touch $LCK_FILE
    chown mh:mh $LCK_FILE
    chmod 666 $LCK_FILE
  fi
}

function pkg_copy {
  echo "[ .. ] Copying package cache"
  cp -v $CACHE/systemd-$VER-x86_64.pkg.tar.zst \
     $PKG_FILE
  chown mh:mh $PKG_FILE
  chmod 666 $PKG_FILE
}

function query_ver {
  echo "[ .. ] Querying a new version of systemd"
  VER=$(pacman -Si systemd | awk -F: '/^Version/ {print $2}')
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

    if echo "$VER" | diff - $VER_FILE >& /dev/null; then
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
  echo "[ .. ] Downloading package"
  $PACMAN -Sddww systemd

  if [[ $? != 0 ]]; then
    echo "[ !! ] Aborting"
    exit 1
  fi

  touch_lock
  mk_update
  pkg_copy
fi
