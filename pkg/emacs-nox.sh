#!/usr/bin/bash

case "$1" in
  '-h'|'--help')
    echo "Usage:       emacs-nox.sh"
    echo "Description: Updates emacs-nox"
  exit 1;;
esac

UPDATE=false

SUDO=doas
PACMAN=pacman
TARGET=emacs-nox
ARCH=x86_64

CACHE=/mnt/ssd/pacman/cache
PKG_DIR=/home/mh/Scripts/pkg
PKG_ROOT=/home/mh/Source/emacs-nox

VER_FILE=$PKG_DIR/emacs-nox.txt

function query_ver {
  echo "[ .. ] Querying a new version of $TARGET"
  VER=$(pacman -Si $TARGET | awk -F: '/^Version/ {print $2}')
  VER=${VER# }
}

function update_stat {
  local VER_FILE_VER=''

  if [[ -f $VER_FILE ]]; then
    VER_FILE_VER=$(cat $VER_FILE)
  else
    echo "[ WW ] No version file is set; assuming out-of-date"
    VER_FILE_VER=""
  fi

  if [[ "$VER" = "$VER_FILE_VER" ]]; then
    echo "[ OK ] Up-to-date"
    exit 0
  else
    echo "[ WW ] Out of date; setting new version in the version file"
    $SUDO $PACMAN -Swwdd $TARGET
    if [[ $? == '0' ]]; then
      echo "[ == ] echo $VER > $VER_FILE"
      echo $VER > $VER_FILE
      UPDATE=true
    else
      echo "[ !! ] Aborting"
    fi
  fi
}

query_ver
update_stat

if $UPDATE; then
  echo "[ == ] tar cache pkg_root"
  tar xvf $CACHE/$TARGET-$VER-$ARCH.pkg.tar.zst \
      --zstd \
      --overwrite \
      --directory $PKG_ROOT
fi

echo "[ OK ] pkg/emacs-nox.sh: Done"
exit 0
