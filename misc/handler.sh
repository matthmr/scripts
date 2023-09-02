#!/bin/sh

case $1 in
  '--help'|'-h')
    echo "Usage:       handler.sh [OPTIONS] URI/FILE"
    echo "Description: Opens a file given a handler for its type"
    echo "Options:
  -u: use URI; default is FILE
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

ext_url=false
int=false
uri=

for arg in $@; do
  case $arg in
    '-u') ext_url=true; continue ;;
    '-i') int=true; continue ;;
    *)    uri=$arg ; continue ;;
  esac
done

if [[ -z $uri ]]; then
  echo "[ !! ] Missing URI or FILE"
  exit 1
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

if $int; then
  echo -n "[ ?? ] Use FILE? [y/N] "
  read ans

  if [[ -z $ans || $ans == 'n' ]]; then
    ext_url=true
  else
    ext_url=false
  fi
fi

if $ext_url; then
  uri=$(ignoreuriparam $uri)
  tmp_uri=$(mktmpuri $uri)
  $FETCHURL -Ls $uri > $tmp_uri
  uri=$tmp_uri
fi

if $int; then
  echo -n "[ ?? ] Override handler? [y/N] "
  read ans

  if [[ -z $ans || $ans == 'n' ]]; then
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
  else
    echo -n "[ .. ] Handle with: "
    read cmd

    if [[ ! -z $cmd ]]; then
      $cmd $uri
    else
      echo "[ !! ] Cmd is empty"
    fi
  fi
fi

if $ext_url; then
  rm -v $uri
fi
