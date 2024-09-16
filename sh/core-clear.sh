#!/usr/bin/bash

COREDIR=$(cat /proc/sys/kernel/core_pattern)
COREDIR=${COREDIR%/*}

case $1 in
  '-h'|'--help')
    echo "Usage:       core-clear.sh [-l|--list/-i|--interactive]"
    echo "Description: Clear the core at \`$COREDIR'"
    exit 1
    ;;
esac

if [[ -z $COREDIR ]]; then
  echo '[ !! ] sysctl is not configure to dump on a directory'
  exit 1
else
  if [[ -z $(ls -1 $COREDIR 2>/dev/null) ]]; then
    echo "[ !! ] Core directory is empty"
    exit 1
  fi

  case $1 in
    '-l'|'--list')
      echo "[ == ] Current date is $(date +%s)"
      echo "[ == ] Current PID is $$"
      ls -lh --color=always $COREDIR
      exit 1;;
    '-i'|'--interactive')
      echo "[ == ] Current date is $(date +%s)"
      echo "[ == ] Current PID is $$"

      for file in $COREDIR/*; do
        printf "[ ?? ] Remove ${file}? [Y/n] "
        read ans

        if [[ $ans = 'y' || -z $ans ]]; then
          rm -rf $file
        elif [[ $ans = 'q' ]]; then
          echo "[ .. ] Quitting"
          break;
        fi
      done 2>/dev/null || {
        echo "[ !! ] Core directory is empty"
        exit 1
      }
      exit 0;;
  esac

  rm -rfv $COREDIR/*
  exit 0
fi
