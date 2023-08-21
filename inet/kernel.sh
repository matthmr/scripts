#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       kernel.sh [-gzr] <dir>"
    echo "Description: Downloads the latest stable version of the linux kernel to <dir>"
    echo "Options:
    -z: download \`xz' compressed kernel source
    -g: download \`gzip' compressed kernel source
    -r: remove kernel from dir
    NOTE: the options above have to be the first argument"
    echo "Variables:
    CURL=\`curl'-like command
    GREP=\`grep'-like command"
    exit 1;;
esac

COMP='xz'
DIR=@KERNEL_DIR@

REMOVE=false
case $1 in
  '-g')
    COMP='gz';;
  '-z')
    COMP='xz';;
  '-r')
    REMOVE=true
    ;;
esac

[[ -z $CURL ]]    && CURL='curl'
[[ -z $GREP ]]    && GREP='grep'
[[ ! -z $2 ]]     && DIR=$2

KERNEL_CDN="https://cdn.kernel.org/pub/linux/kernel"
XQUERY="/x/*"

function linkname {
  echo "$1" | sed "s:\.tar\.$2::"
}

if $REMOVE; then
  CKERNEL=$(ls -1 $DIR | fzf)
  if [[ -z $CKERNEL ]]; then
    echo "[ !! ] Abort"
    exit 1
  else
    rm -rfv $DIR/$CKERNEL
    exit 0
  fi
fi

echo "[ .. ] Searching for kernel major version"
MAJOR=$($CURL -s "$KERNEL_CDN/" |\
          $GREP -o 'v[0-9]\+\.x' | uniq |\
          sed 's:.*\([0-9]\+\).*:\1:' | tail -n 1)

echo "[ .. ] Searching for kernel minor version"
MINOR_PAGE=$($CURL -s "$KERNEL_CDN/v$MAJOR.x/")
MINOR=$(echo "$MINOR_PAGE" | $GREP -o ">linux-$MAJOR.*\.tar\.\(${COMP}\)")
#| sed -e 's:^>linux-::' -e "s:\.tar\.${COMP}::" -e 's:\.::g')

CMINOR=$(echo "$MINOR" | sed 's:>::' | fzf)

if [[ -z $CMINOR ]]; then
  echo "[ !! ] Abort"
  exit 1
else
  LINUX_DIR=$(linkname $CMINOR $COMP)

  if [[ -d $DIR/$LINUX_DIR ]]; then
    echo "[ WW ] Linux is already installed at $DIR. Consider removing it"
    exit 1
  fi

  mkdir $DIR/$LINUX_DIR

  $CURL "$KERNEL_CDN/v$MAJOR.x/$CMINOR" > $DIR/$LINUX_DIR/$CMINOR
fi
