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

KERNEL_BZIMAGE=/boot/vmlinuz-linux
EFISTUB=/boot/EFI/BOOT/BOOTx64.EFI

/usr/bin/cp -v $KERNEL_BZIMAGE $EFISTUB
