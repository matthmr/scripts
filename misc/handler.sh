#!/usr/bin/sh

case $1 in
  '--help'|'-h')
    echo "Usage:       handler.sh [OPTIONS] URI/FILE"
    echo "Description: Opens a URI/FILE given a handler for its type"
    echo "Options:
  -p: ignore URI parameters
  -f: fork children, exit main handler. cannot be used with \`-d'
  -d: use URI2FILE for fetchables URIs
  -i: run interactively"
    exit 0;;
esac

#### DEFAULTS

BROWSER=w3m
PAGER=less
EDITOR=emacsc
AUDIOPLAYER=mpv
VIDEOPLAYER=mpv

FETCHURL=curl
IMGVIEW=feh
GIFVIEW=nsxiv
PDFVIEW=zathura
DEC=dec

# HIGHLIGHT [URI]
function HIGHLIGHT {
  local uri=$1

  highlight --force=text -O ansi "$uri" | $PAGER
}

#### CMDLINE PARSER

int=false
fork=false
as='remote'
ignore_params=false
remote_uri=false

ignore_params_def='n'
local_def='n'
fork_def='n'
override_def='n'

handler=handle_uri
job=""
uri=""

for arg in $@; do
  case $arg in
    '-d') as='local'; handler=handle_file; local_def='y' ;;
    '-i') int=true ;;
    '-p') ignore_params=true; ignore_params_def='y' ;;
    '-f') fork=true; fork_def='y' ;;
    *) uri=$arg ;;
  esac
done

if [[ -z $uri ]]; then
  echo "[ !! ] Missing URI or FILE"
  exit 1
fi

# TODO: support more protocols
if [[ $uri =~ ^https?:// ]]; then
  remote_uri=true
else
  handler=handle_file
  local_def='y'
fi

#### FUNCTIONS

# ignoreuriparam URI
function ignoreuriparam {
  local uri=$1
  echo ${uri%%\?*}
}

# mktmpuri URI
function mktmpuri {
  local uri=$1
  echo /tmp/uri-$(echo "$uri" | md5sum | cut -d' ' -f1)
}

# fetch_into_local URI
function fetch_into_local {
  if $remote_uri; then
    local uri=$1

    tmp_uri=$(mktmpuri $uri)
    $FETCHURL -Ls $uri > $tmp_uri
  fi

  echo $tmp_uri
}

# prompt_yn PROMPT DEFAULT
function prompt_yn {
  local prompt=$1
  local def=$2
  local opts=""

  case $def in
    'y') opts="[Y/n] " ;;
    'n') opts="[y/N] " ;;
  esac

  echo -n "[ ?? ] $prompt? $opts"
}

# with_prompt_response ANS DEFAULT
function prompt_y {
  local ans=$1
  local def=$2

  case $def in
    'y') [[ -z $ans || $ans == 'y' ]] ;;
    'n') ! [[ -z $ans || $ans == 'n' ]] ;;
  esac
}

# prompt_for_handler URI JOB
function prompt_for_handler {
  local uri=$1
  local job=${@:2}

  echo -n "[ .. ] Handle with: "
  read cmd

  if [[ ! -z $cmd ]]; then
    if [[ $cmd =~ ^"f " ]]; then
      cmd=${cmd/f /}
      f=$uri
      eval $job "$cmd"
    else
      $job "$cmd" "$uri"
    fi
  else
    echo "[ !! ] Cmd is empty"
  fi
}

# handle_file FILE JOB
function handle_file {
  local uri=$1
  local job=${@:2}

  case $uri in
    *.pgp) $DEC $uri | HIGHLIGHT; return 0 ;;
  esac

  case "$(file --dereference --brief --mime-type -- "$uri")" in
    image/gif) $job $GIFVIEW $uri ;;
    image/*) $job $IMGVIEW $uri ;;
    video/*) $job $VIDEOPLAYER $uri ;;
    audio/* | application/octet-stream) $AUDIOPLAYER $uri ;;
    # this only works if the program runs in a terminal
    text/html) $BROWSER $uri ;;
    */pdf) $job $PDFVIEW $uri ;;
    *) HIGHLIGHT $uri;;
  esac
}

# handle_uri URI JOB
function handle_uri {
  local uri=$1
  local job=${@:2}

  case $uri in
    *.png|*.jpg|*.jpeg|*.webp|*.bmp) $job $IMGVIEW $uri ;;
    *.mp4|*.mkv|*.mov|*.webm|*.gif) $job $VIDEOPLAYER $uri ;;
    *.ogg|*.mp3) $AUDIOPLAYER $uri ;;
    *.html) $BROWSER $uri ;;
    *.pdf) $job $PDFVIEW $uri ;;
    *) $BROWSER $uri ;;
  esac
}

#### MAIN

# fetch
if $remote_uri; then
  # uri
  ans=$ignore_params_def

  if $int; then
    prompt_yn "Ignore URI params" $ignore_params_def
    read ans
  fi

  if $(prompt_y "$ans" "$ignore_params_def"); then
    uri=$(ignoreuriparam $uri)
  fi

  ans=$local_def

  if $int; then
    prompt_yn "Fetch locally" $local_def
    read ans
  fi

  if $(prompt_y "$ans" "$local_def"); then
    uri=$(fetch_into_local $uri)
    handler=handle_file
  else
    handler=handle_uri
  fi
fi

# job
#   fork-if: !(as == local && remote_uri): we cannot fork if we have a local
#   file, because we immediately remove it in the end
while [[ $as != 'local' || $remote_uri != 'true' ]]; do
  ans=$fork_def

  # we'd have to call `wait' anyway, might as well not even fork at all
  if [[ $remote_uri == 'true' && $handler == 'handle_file' ]]; then
    break
  fi

  if $int; then
    prompt_yn "Fork" $fork_def
    read ans
  fi

  if $(prompt_y "$ans" "$fork_def"); then
    job="setsid -f"
    used_job=true
  fi

  break
done

if $int; then
  prompt_yn "Override handler" $override_def
  read ans

  if $(prompt_y "$ans" "$override_def"); then
    handler="prompt_for_handler"
  fi
fi

$handler "$uri" "$job"

if [[ $remote_uri == 'true' && $handler == 'handle_file' ]]; then
  rm -v "$uri"
fi
