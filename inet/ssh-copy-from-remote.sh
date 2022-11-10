#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       ssh-copy-from-remote.sh <user> <host> <remote file> <local file> [ssh options]"
		echo "Description: Copies a file from a remote ssh server"
		echo "
		VARIABLES:
			SCP: [ssh copy client]"
		exit 1
		;;
esac

[[ -z $SCP ]] && SCP=scp

USER=$1
HOST=$2
REMOTE=$3
LOCAL=$4

case ${0##*/} in
  'ssh-copy-from-remote.sh')
    SCP_1="$USER@$HOST:$REMOTE"
    SCP_2="$LOCAL";;
  'ssh-copy-to-remote.sh')
    SCP_1="$LOCAL"
    SCP_2="$USER@$HOST:$REMOTE";;
  *)
    echo "[ !! ] What are you doing?"
    exit 1;;
esac

$SCP "${@:5}" $SCP_1 $SCP_2
