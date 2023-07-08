#!/usr/bin/bash

USER_SHELL=zsh
COMMAND=$1
AS=${COMMAND##*:}
COMMAND=${COMMAND%%:*}

case $1 in
  '-h'|'--help')
    echo "Usage:       lock.sh"
    echo "Description: Lock the system ACPI reboot/shutdown to update packages"
    echo "Variables:
  SUDO: sudo-like command"
    exit 1;;
esac

# carve out the command
PACMAN= PARU= CRON= EFISTUB=
len=${#COMMAND}
len=$((len - 1))
for (( i = 0 ; i <= len; i++ )); do
  case ${COMMAND:i:1} in
    'p') PACMAN=y;;
    'n') PARU=y;;
    'e') EFISTUB=y;;
    'c') CRON=y;;
    'd') CRONMSG=y;;
  esac
  COMMAND=${COMMAND:i}
done

case $AS in
  'shutdown')
    COMMAND="poweroff now";;
  'reboot')
    COMMAND="reboot now";;
    *)
    echo "[ !! ] Cannot run this script manually; exiting..."
    exit 1;;
esac

[[ -z $SUDO ]] && SUDO=doas

function _man {
  read -p "[ ?? ] Update ManDB? [Y/n] " ans

  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
    echo "Ignore lock:" "lock was ignored for man"
    return 0
  fi

  while ! $SUDO mandb; do continue; done
}

function _pacman {
  read -p "[ ?? ] Update packages (pacman)? [Y/n] " ans

  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
    echo "Ignore lock:" "lock was ignored for pacman"
    return 0
  fi

  read -p "[ ?? ] Manual review? [y/N] " ans
  [[ $ans = 'y' ]] && local MANUAL=y || local MANUAL=n

  if [[ $MANUAL = 'y' ]]
  then
    echo "[ .. ] Updating pacman database for manual review"
    while ! $SUDO pacman -Sy; do continue; done
    echo "[ .. ] Generating new pacman updatable package file"
    pacman -Qu > /tmp/pacman/pacman-update-raw
    sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' /tmp/pacman/pacman-update-raw |\
      awk '{print $1}' > /tmp/pacman/pacman-update
    echo "[ .. ] Setting permissions"
    chown -Rv mh:mh /tmp/pacman/pacman-update /tmp/pacman/pacman-update-raw
    chmod -Rv a+w /tmp/pacman/pacman-update /tmp/pacman/pacman-update-raw
    echo "[ .. ] Listing updatable packages"
    /bin/less -R /tmp/pacman/pacman-update-raw
  fi

  read -p "[ ?? ] Check against wiki? [Y/n] " ans
  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
  else
    if [[ $MANUAL = 'y' ]]
    then
      #/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/pacman-update | /bin/less
      /home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/pacman-update | /bin/less
    else
      #/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/pacman | /bin/less
      /home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/pacman | /bin/less
    fi
  fi

  read -p "[ ?? ] Handle SSD packages (pacman)? [Y/n] " ans
  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
  else # open a new shell, wait for it to die, then continue
    echo "[ OK ] Waiting for SSD packages to be handled"
    unset XINITSLEEP
    unset XINITSLEEPARGS
    $USER_SHELL
  fi

  echo "[ .. ] Updating system (pacman)"
  $SUDO pacman -Su

  echo "[ .. ] Removing lock"
  rm -v /tmp/pacman/lock-pacman
}

function _paru {
  read -p "[ ?? ] Update packages (AUR)? [Y/n] " ans

  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
    echo "Ignore lock:" "lock was ignored for paru"
    return 0
  fi

  read -p "[ ?? ] Manual review? [y/N] " ans
  [[ $ans = 'y' ]] && local MANUAL=y || local MANUAL=n

  if [[ $MANUAL = 'y' ]]
  then
    echo "[ .. ] Updating database for manual review"
    paru -Sy
    echo "[ .. ] Generating new pacman updatable package file"
    paru -Qu > /tmp/pacman/paru-update-raw
    sed -E 's/\x1b\[0;1m|\x1b\[0;32m//g' /tmp/pacman/paru-update-raw |\
      awk '{print $1}' > /tmp/pacman/paru-update
    echo "[ .. ] Setting permissions"
    chown -Rv mh:mh /tmp/pacman/paru-update /tmp/pacman/paru-update-raw
    chmod -Rv a+w /tmp/pacman/paru-update /tmp/pacman/paru-update-raw
    echo "[ .. ] Listing updatable packages"
    /bin/less -R /tmp/pacman/paru-update-raw
  fi

  read -p "[ ?? ] Check against wiki? [Y/n] " ans
  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
  else
    if [[ $MANUAL = 'y' ]]
    then
      #/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/paru-update | /bin/less
      /home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/paru-update | /bin/less
    else
      #/home/mh/Scripts/find/wiki-find-pacman.sh /tmp/pacman/paru | /bin/less
      /home/mh/Scripts/find/wiki-find-pacman-index.sh /tmp/pacman/paru | /bin/less
    fi
  fi

  read -p "[ ?? ] Handle SSD packages? [Y/n] " ans
  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
  else # open a new shell, wait for it to die, then continue
    echo "[ OK ] Waiting for SSD packages to be handled"
    unset XINITSLEEP
    unset XINITSLEEPARGS
    $USER_SHELL
  fi

  echo "[ .. ] Updating system (AUR)"
  paru -Su

  echo "[ .. ] Removing lock"
  rm -v /tmp/pacman/lock-paru
}

function _cron {
  local SCRIPTS="$(/bin/find /tmp/cron/ -type f -name '*.sh' 2>/dev/null)"
  read -p "[ ?? ] Cron-like script job found. Run it? [Y/n] " ans
  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
    echo "Ignore lock:" "lock was ignored for cron"
    for file in $(echo $SCRIPTS|tr '\n' ' '); do rm -v $file ${file%%.sh}; done #remove the files
    return 0
  else
    while read file
    do
      echo "[ .. ] Executing $file"
      sleep 1
      sh $file
      rm -v $file ${file%%.sh} #remove the files as we execute them
    done <<< "$SCRIPTS"
  fi
}

function _cronmsg {
  local JOBS="$(/bin/find /tmp/cron/ -type f -not -name '*.sh' 2>/dev/null)"
  echo "[ .. ] Cron-like message job found"

  # open a shell do to the jobs, when closing, prompt for openrc hand-over
  unset XINITSLEEP
  unset XINITSLEEPARGS
  $USER_SHELL
  for file in $(echo $JOBS|tr '\n' ' '); do rm -v $file; done #remove the files
}

function _efistub {
  read -p "[ ?? ] Update packages (efistub)? [Y/n] " ans

  if [[ $ans = 'n' ]]
  then
    echo "[ !! ] Ignoring ... "
    echo "Ignore lock:" "lock was ignored for efistub"
    return 0
  fi

  while ! $SUDO /home/mh/Scripts/root/efistub.sh; do continue; done
}

if [[ ! -z $PACMAN ]]; then
  _pacman
  _man
fi

[[ ! -z $PARU ]]    && _paru
[[ ! -z $CRON ]]    && _cron
[[ ! -z $CRONMSG ]] && _cronmsg
[[ ! -z $EFISTUB ]] && _efistub

read -p "[ ?? ] Hand over to openrc? [Y/n] " ans
if [[ $ans = 'n' ]]
then
  echo "[ !! ] Ignoring ... "
  exit 1
else
  echo "[ OK ] Handing over to openrc"
  echo "ACPI event sent:" "waiting to send ACPI event; press C-c to ignore it"
  sleep 5
  exec $SUDO $COMMAND
fi
