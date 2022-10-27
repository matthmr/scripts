#!/usr/bin/env bash

function usage {
		echo "Usage:       edit-copy.sh [-ceid] <CLIPEDITOR>"
		echo "Description: Uses the editor stored in the \`CLIPEDITOR' variable to edit a copy file.
If run with the \`-c' flag, it edits a blank file a save to a file copy
If run with the \`-e' flag, it edits the latest file copy
If run with the \`-i' flag, it reads from \`/tmp/clipboard'
If run with the \`-d' flag, it writes to \`/tmp/clipboard'"
    echo "Variables:
    - CLIPEDITOR: editor-like command
    - XSEL: xsel-command"
}

case $1 in
	'-h'|'--help')
    usage
		exit 1;;
esac

[[ -z $CLIPEDITOR ]] && CLIPEDITOR=emacsxc
[[ -z $XSEL ]]       && XSEL=xsel
CLIP=/tmp/clipboard

FLAG=false

if [[ ! -z $1 ]]
then
  case $1 in
  '-c')
    printf "" > $CLIP
    FLAG=true;;
  '-e')
    xsel --logfile /dev/null --clipboard -o > $CLIP
    FLAG=true;;
  '-i')
    xsel --logfile /dev/null --clipboard -i < $CLIP
    exit 1;;
  '-d')
    xsel --logfile /dev/null --clipboard -o > $CLIP
    exit 1;;
  *)
    usage
		exit 1;;
  esac
else
  usage
	exit 1
fi

if $FLAG; then
  if [[ ! -z $2 ]]; then
    CLIPEDITOR=${@:2}
  fi
fi

$CLIPEDITOR /tmp/clipboard
xsel --logfile /dev/null --clipboard -i     < $CLIP
