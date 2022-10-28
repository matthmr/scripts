#!/usr/bin/sh

_help() {
		echo "Usage:       toggle-ptrace.sh [status|enable|disable]"
		echo "Description: Toggles \`ptrace' for any user-owned process"
		exit 1
}

COMMAND=$1

_check_root() {
		if [[ $USER != root ]]; then
				echo "[ !! ] Need to be root"
				exit 1
		fi
}

case $COMMAND in
	'status')
		PTRACE=$(sysctl -n kernel.yama.ptrace_scope)
		if [[ $PTRACE = 1 ]]; then
			echo "[ !! ] \`ptracing' is disabled"
		else
			echo "[ OK ] \`ptracing' is enabled"
		fi

		exit 0
		;;
	'enable')
		_check_root
		echo "[ .. ] Enabling ptrace"
		sysctl -w kernel.yama.ptrace_scope=0
		exit 0
		;;
	'disable')
		_check_root
		echo "[ .. ] Disabling ptrace"
		sysctl -w kernel.yama.ptrace_scope=1
		exit 0
		;;
	'--help'|'-h')
		_help
		;;
	*)
		_help
		;;
esac

_check_root

PTRACE=$(sysctl -n kernel.yama.ptrace_scope)

if [[ $PTRACE = 1 ]]; then
		echo "[ .. ] Enabling ptrace"
		sysctl -w kernel.yama.ptrace_scope=0
else
		echo "[ .. ] Disabling ptrace"
		sysctl -w kernel.yama.ptrace_scope=1
fi

echo "[ OK ] Done"
