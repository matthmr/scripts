#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       proton-run.sh [-e] [dir|prog] [prog]"
		echo "  * -e : pass-in \`prog' as the program executable"
		echo "  * : pass-in \`dir' as the base dir of the game and \`prog' the program executable"
		echo "Description: Generates a proton command to run [prog]"
		echo "Variables "
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
