#!/usr/bin/sh

case $1 in
  '-h'|'--help')
    echo "Usage:       git-server.sh [-d] [-l <path>] <path>"
    echo "Description: Starts a git server serving at <path>, or PWD"
    echo "Options:
  -d: detach from the terminal (no)
  -l: log destination (stderr)"
    exit 1
esac

BASE_PATH=$PWD
DETACH=
LOG_DESTINATION='--log-destination=stderr'

lock_log=false

for arg in $@; do
  if $lock_log; then
    LOG_DESTINATION="--log-destination=$arg"
    lock_log=false
    continue
  fi

  case $arg in
    '-d')
      DETACH=--detach;;
    '-l')
      lock_log=true;;
    *)
      BASE_PATH=$arg;;
  esac
done

if $lock_log; then
  echo "[ !! ] Bad usage. See \`--help'"
fi

echo "[ == ] git daemon --base-path=$BASE_PATH --export-all --enable=receive-pack $DETACH $LOG_DESTINATION"
git daemon \
    --base-path=$BASE_PATH\
    --export-all \
    --enable=receive-pack \
    $DETACH $LOG_DESTINATION
