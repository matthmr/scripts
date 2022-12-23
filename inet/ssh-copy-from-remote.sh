#!/usr/bin/sh

AS=${0##*/}

[[ -z $SCP ]] && SCP=scp

case $1 in
  '-h'|'--help')
    if [[ $AS = 'ssh-copy-from-remote.sh' ]]; then
      echo "Usage:       ssh-copy-from-remote.sh <user> <host> <remote file> <local file> [ssh options]"
      echo "Description: Copies a remote file from a remote ssh server"
      echo "VARIABLES:
      SCP: [ssh copy client]"
    elif [[ $AS = 'ssh-copy-to-remote.sh' ]]; then
      echo "Usage:       ssh-copy-to-remote.sh <local file> <user> <host> <remote file> [ssh options]"
      echo "Description: Copies a local file to a remote ssh server"
      echo "VARIABLES:
      SCP: [ssh copy client]"
    fi
    exit 1;;
esac

case $AS in
  'ssh-copy-from-remote.sh')
    USER=$1
    HOST=192.168.$2
    REMOTE=$3
    LOCAL=$4

    [[ -z $USER || -z $HOST || -z $REMOTE || -z $LOCAL ]] && {
      echo "[ !! ] Wrong usage. See --help"
      exit 1
    }

    SCP_FROM="$USER@$HOST:$REMOTE"
    SCP_TO="$LOCAL";;
  'ssh-copy-to-remote.sh')
    LOCAL=$1
    USER=$2
    HOST=192.168.$3
    REMOTE=$4

    [[ -z $USER || -z $HOST || -z $REMOTE || -z $LOCAL ]] && {
      echo "[ !! ] Wrong usage. See --help"
      exit 1
    }

    SCP_FROM="$LOCAL"
    SCP_TO="$USER@$HOST:$REMOTE";;
  *)
    echo "[ !! ] What are you doing?"
    exit 1;;
esac

echo "[ == ] Calling as: $SCP "${@:5}" $SCP_FROM $SCP_TO"
$SCP "${@:5}" $SCP_FROM $SCP_TO
