#!/usr/bin/sh

COMMAND=/usr/bin/nvidia-sleep.sh
MODE=

case ${0##*/} in
  'nvidia-sleep-suspend-or-hibernate.sh')
    case $OP in
      'suspend')
        MODE=suspend;;
      'hibernate')
        MODE=hibernate;;
      *) exit 1;;
    esac;;
  'nvidia-sleep-resume.sh')
    MODE=resume;;
esac

$COMMAND $MODE
#echo $COMMAND $MODE
