#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       ssh-copy-from-remote.sh <user> 192.168.<host> <remote> <local> [ssh options]"
		echo "Description: Copies a file from a remote ssh server"
		echo "
		VARIABLES:
			SCP: [ssh copy client]"
		exit 1
		;;
esac

[[ -z $SCP ]] && SCP=scp

USER=$1
HOST=192.168.$2
REMOTE=$3
LOCAL=$4

$SCP "${@:5}" "$USER@$HOST:$REMOTE" "$LOCAL"
