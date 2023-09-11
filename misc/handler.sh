#!/usr/bin/bash

case $1 in
  '--help'|'-h')
    echo "Usage:       handler.sh [OPTIONS] URI/FILE"
    echo "Description: Opens a file given a handler for its type"
    echo "Options:
  -d: use URI2FILE for fetchables URIs
  -i: run interactively"
    exit 0;;
esac

#### DEFAULTS

BROWSER=w3m
EDITOR=emacsc
AUDIOPLAYER=mpv
VIDEOPLAYER=mpv

FETCHURL=curl
IMGVIEW=feh
GIFVIEW=nsxiv
PDFVIEW=mupdf

#### CMDLINE PARSER

int=false
fetch=false
download=false
uri=

for arg in $@; do
  case $arg in
    '-d')  download=true; continue ;;
    '-i')  int=true; continue ;;
    *)     uri=$arg ; continue ;;
  esac
done

if [[ -z $uri ]]; then
  echo "[ !! ] Missing URI or FILE"
  exit 1
fi

# TODO: support more protocols
if [[ $uri =~ ^https?:// ]]; then
  fetch=true
fi

#### MAIN

function ignoreuriparam {
  local uri=$1
  echo ${uri%%\?*}
}

function mktmpuri {
  local uri=$1
  echo /tmp/uri-$(echo "$uri" | md5sum | cut -d' ' -f1)
}

function fetch_into_local {
  local uri=$1

  uri=$(ignoreuriparam $uri)
  tmp_uri=$(mktmpuri $uri)
  $FETCHURL -Ls $uri > $tmp_uri

  echo $tmp_uri
}

function prompt_for_handler {
  echo -n "[ .. ] Handle with: "
  read cmd

  if [[ ! -z $cmd ]]; then
    $cmd $uri
  else
    echo "[ !! ] Cmd is empty"
  fi
}

function handle_file {
  local uri=$1

  case "$(file --dereference --brief --mime-type -- "$uri")" in
    image/gif) $GIFVIEW $uri ;;
    image/*) $IMGVIEW $uri ;;
    video/*) $VIDEOPLAYER $uri ;;
    audio/* | application/octet-stream) $AUDIOPLAYER $uri ;;
    # this only works if the program runs in a terminal
    text/html) $BROWSER $uri ;;
    */pdf) $PDFVIEW $uri ;;
    *) $EDITOR $uri ;;
  esac
}

function handle_uri {
  local uri=$1

  uri=$(ignoreuriparam $uri)

  case $uri in
    *.png|*.jpg|*.jpeg|*.webp|*.bmp) $IMGVIEW $uri ;;
    *.mp4|*.mkv|*.mov|*.webm|*.gif) $VIDEOPLAYER $uri ;;
    *.ogg|*.mp3) $AUDIOPLAYER $uri ;;
    *.html) $BROWSER $uri ;;
    *.pdf) $PDFVIEW $uri ;;
    *) $BROWSER $uri ;;
  esac
}

if $int; then
  if $fetch; then
    echo -n "[ ?? ] Fetch locally? [Y/n] "
    read ans

    if [[ -z $ans || $ans == 'y' ]]; then
      uri=$(fetch_into_local $uri)
      handler=handle_file
    else
      handler=handle_uri
    fi
  else
    handler=handle_file
  fi

  echo -n "[ ?? ] Override handler? [y/N] "
  read ans

  if [[ -z $ans || $ans == 'n' ]]; then
    eval $handler "$uri"
  else
    prompt_for_handler
  fi

else
  if $fetch; then
     if $download; then
       uri=$(fetch_into_local $uri)
       handler=handle_file
     else
       handler=handle_uri
     fi
  else
    handler=handle_file
  fi

  eval $handler $uri
fi

if [[ $handler == 'handle_file' ]]; then
  rm -v $uri
fi
