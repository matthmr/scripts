#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       core-clear.sh [-l|--list]"
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
	pushd $COREDIR > /dev/null
	case $1 in
		'-l'|'--list')
			/bin/ls -lh --color=always
			popd > /dev/null
			exit 1
			;;
	esac
	find -type f | xargs rm -rv
	popd > /dev/null
}
