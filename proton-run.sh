#!/usr/bin/sh

function usage {
	printf "\
VARIABLES:
	PROTON : proton command path(file)
	STEAM : common steam client path(dir)
	PREFIX : wine prefix(dir)
CMDLINE:
	proton-run.sh <base:base dir of the game> <exec:path to game executable>
	proton-run.sh -e <exec:path to game executable>\n"
	return 0
}

case $1 in
	'-h'|'--help')
		usage
		exit 1
		;;
esac

if [[ $1 != '-e' ]]
then
	BASE=$1
	EXEC=$2
else
	EXEC=$2
	BASE=${EXEC%/*}
	EXEC=${EXEC##*/}
fi

{
	[[ -z $BASE || -z $EXEC ]]
} && {
	usage
	exit 1
}

[[ -z $PROTON ]] && PROTON="/mnt/ssd/SteamLibrary/steamapps/common/Proton - Experimental/proton"
[[ -z $STEAM ]] && STEAM="/home/mh/.local/share/Steam"
[[ -z $PREFIX ]] && PREFIX="/mnt/ssd/wine"

echo "STEAM_COMPAT_CLIENT_INSTALL_PATH=\"$STEAM\" STEAM_COMPAT_DATA_PATH=\"$BASE\" WINEPREFIX=\"$PREFIX\" \"$PROTON\" run \"$BASE/$EXEC\""
