#!/usr/bin/sh

# [ -z `pidof dunst` ] && dunst & # started on `wminit'
# [ -z `pidof xcompmgr` ] && xcompmgr & # I have no need for a compositor


if [[ -z `pidof clipmenud` ]]; then
	CM_LAUNCHER=dmenu \
	CM_HISTLENGTH=20 \
	CM_MAX_CLIPS=20 \
	CM_SELECTIONS=clipboard \
	clipmenud &
fi

if [[ -z `pidof nitrogen` ]]; then
		nitrogen --restore &
fi

if [[ $wm =~ dwm && -z `pidof fbxkb` ]]; then
		fbxkb &
fi

if [[ -z `pidof sxhkd` ]]; then
	 sxhkd >& /dev/null &
fi
