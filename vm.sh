#!/usr/bin/bash

function help {
  echo "Usage:       vm.sh [opts...] -- [extra opts...]"
  echo "Description: Sets options to start a VM"
  echo "Options:
  Include flags:
    +a: enable host audio
    +n: enable host networking (port forwarding)

  Key-value pair flags:
    iso:<file>: vm iso file
    disk:<file>: vm virtual disk
    mem:<n>: host memory amount
    cpu:<n>: host cpu core count

  NOTE:
    [extra opts...] may be raw options to the vm command
    use \`@' instead of \`\"' to denote joining"
  echo "Variables:
    VM=vm command"
  exit 1
}

case "$1" in
  '-h'|'--help')
    help;;
esac

[[ -z $1 ]] && help
[[ -z $VM ]] && VM='qemu-system-x86_64'

VM_CMDLINE_COMMON="-enable-kvm -cpu host"
VM_CMDLINE="$VM_CMDLINE_COMMON"

OPT_INC=('a' 'n')
OPT_PAIR=('iso' 'disk' 'mem' 'cpu')

AUDIO="-audiodev alsa,id=alsa,driver=alsa,out.frequency=48000,out.channels=2,out.dev=default,out.try-poll=off,timer-period=1000 \
-device ich9-intel-hda \
-device hda-output,audiodev=alsa"
NETWORK="-net user,id=net0,hostfwd=tcp::60022-:22 \
-net nic"

IFS=' '

function die_opt {
  echo "[ !! ] Invalid option"
  exit 1
}

function parse_include_opt {
  opt=${1:1}
  len=${#opt}

  [[ -z $opt ]] && return 1

  for ((iter = 0; iter < len; iter++)); do
    local _opt=${opt:$iter:1}
    local found=false

    for inc in ${OPT_INC[@]}; do
      if [[ $_opt = $inc ]]; then
        found=true

        case $_opt in
          'a') VM_CMDLINE+=" $AUDIO"   ; continue;;
          'n') VM_CMDLINE+=" $NETWORK" ; continue;;
          *)   return 1;;
        esac
      fi
    done

    if ! $found; then
      return 1
    fi
  done
}

function parse_pair_opt {
  key=${1%%:*}
  value=${1#*:}

  [[ -z $key ]] && return 1

  local found=false
  for pair in ${OPT_PAIR[@]}; do

    if [[ $key = $pair ]]; then

      found=true
      case $key in
        "iso")  VM_CMDLINE+=" -boot d -cdrom $value" ; break;;
        "disk") VM_CMDLINE+=" -boot c -hda $value" ; break;;
        "mem")  VM_CMDLINE+=" -m $value" ; break;;
        "cpu")  VM_CMDLINE+=" -smp $value" ; break;;
        *)      return 1;;
      esac
    fi
  done

  if ! $found; then
    return 1
  fi
}

RAW_OPTS_OFF=
function parse_args {
  local off=1

  for arg in $@; do

    if [[ $arg =~ ^\+ ]]; then
      parse_include_opt $arg || die_opt
    elif [[ $arg =~ : ]]; then
      parse_pair_opt $arg || die_opt
    elif [[ $arg =~ ^--$ ]]; then
      RAW_OPTS_OFF=$((off+1))
      return 0
    else
      echo "[ !! ] Invalid option"
      exit 1
      VM_CMDLINE+=" $arg"
    fi

    off=$((off+1))
  done
}

function parse_raw_args {
  VM_CMDLINE+=" $(echo $@ | sed "s:@:\":g")"
}

parse_args $@

[[ ! -z $RAW_OPTS_OFF ]] && parse_raw_args "${@:$RAW_OPTS_OFF}"

VM_CMDLINE=$(echo $VM_CMDLINE | sed "s:~:$HOME:g")

$VM $VM_CMDLINE &
