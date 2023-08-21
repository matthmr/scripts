#!/usr/bin/bash

case $1 in
	'-h'|'--help')
		echo "Usage:       core-clear.sh [-l|--list] [-i|--interactive]"
		echo "Description: Clear the core at \``cat /proc/sys/kernel/core_pattern`'"
		exit 1
		;;
esac

COREDIR=$(sysctl -n kernel.core_pattern)
COREDIR=${COREDIR%/*}

{
	[[ -z $COREDIR ]]
} && {
	echo '[ !! ] sysctl is not configure to dump on a directory'
	exit 1
} || {
  if [[ -z $(find $COREDIR -type f 2>/dev/null) ]]; then
    echo "[ !! ] Core directory is empty"
    exit 1
  fi

	pushd $COREDIR > /dev/null
	case $1 in
		'-l'|'--list')
			/bin/ls -lh --color=always
			popd > /dev/null
			exit 1;;
    '-i'|'--interactive')
      echo "[ == ] Current date is $(date +%s)"
      echo "[ == ] Current PID is $$"

      for file in $COREDIR/*; do
        printf "[Y/n ] Remove ${file}? "
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

	rm -rv $COREDIR/* 2>/dev/null
	popd > /dev/null
  exit 0
}
