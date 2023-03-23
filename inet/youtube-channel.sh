#!/usr/bin/bash

# Integrated by mH (https://github.com/matthmr)

#*****************************************************
# change anything that is followed by "#change this" #
#*****************************************************

# youtube-channel.sh [-c:clear-query, -l:list queries] <id>

# TODO: fetch more data from `/videos`?

YOUTUBE_BASE="https://www.youtube.com"
YOUTUBE_WATCH="$YOUTUBE_BASE/watch?v="
BASE=/tmp/youtube

case $1 in
  '-h'|'--help')
    echo "Usage:       ytch @\"<handle>\"|\"<id>\" [options] "
		echo "Description: Generates a list of 30 videos for a given channel"
    echo "Options:
  -l : list queries
  -c : clear query
  -C : clear all"
		echo "Variables:
  JQ       : jq-like command
  CURL     : curl-like command
  GREP     : grep-like command
  SED      : sed-like command
  AWK      : awk-like command
  FZF      : fzf-like command
  MPV      : mpv-like command
  MPV_OPTS : extra mpv options"
		exit 1;;
  '-v'|'--version')
    echo "ytch v1.0.0"
    exit 1;;
esac

if [[ $# -le 0 ]]
then
	echo "[ !! ] Bad usage. See ytch --help" 1>&2
	exit 1
fi

[[ -z $MPV_OPTS ]] && MPV_OPTS="--ytdl-format=best \
                                --audio=auto --video=auto"

[[ -z $CURL ]] && CURL=curl
[[ -z $GREP ]] && GREP=grep
[[ -z $SED ]]  && SED=sed
[[ -z $AWK ]]  && AWK=awk
[[ -z $MPV ]]  && MPV=mpv
[[ -z $FZF ]]  && FZF=fzf
[[ -z $JQ ]]   && JQ=jq

JQUERY=".contents.twoColumnBrowseResultsRenderer.tabs[1].tabRenderer.content.richGridRenderer.contents[] | \
.richItemRenderer.content.videoRenderer | \
select(. != null) | \
.title.runs[0].text, \
.videoId, \
.publishedTimeText.simpleText, \
.lengthText.simpleText, \
.viewCountText.simpleText"

function ytch_load_video {
  echo "[ == ] Running: $MPV $MPV_OPTS $1"
  $MPV $MPV_OPTS "$1"
}

function ytch_search {
  local res=$(
    $AWK -F"\x00" '{printf " %s [%s] [%s] [%s]\n", $1, $3, $4, $5}' $1 |\
      cat -n | $FZF)

  if [[ -z $res ]]; then
    echo "[ !! ] Ignoring" 1>&2
    exit 1
  fi

  local ln=$(echo "$res" | awk '{print $1}')
  local link=$(cat $1 | sed -n "${ln}p;${ln}q" | awk -F"\x00" '{print $2}')
  ytch_load_video "${YOUTUBE_WATCH}${link}"
}

for arg in "$@"; do
  case $arg in
    '-l')
      if [[ -d $BASE ]]
      then
        find $BASE -type d | sed -n '2,$s:/tmp/youtube/: -> :p'
        exit 1
      else
        echo "[ !! ] No base was found" 1>&2
        exit 1
      fi;;
    '-c')
      if [[ -d $BASE ]]
      then
        if [[ -d "$BASE/$ID" ]]
        then
          echo "[ .. ] Removing $ID..." 1>&2
          rm -rfv "$BASE/$ID"
          exit 0
        else
          echo "[ !! ] No such id $ID was found" 1>&2
          exit 1
        fi
      else
        echo "[ !! ] No base was found" 1>&2
        exit 1
      fi;;
    '-C')
      if [[ -d $BASE ]]
      then
        rm -rfv $BASE
        exit 0
      else
        echo "[ !! ] No base was found" 1>&2
        exit 1
      fi;;
    *)
      ID=$arg;;
  esac
done

if [[ ! -d $BASE ]]; then
  TMP=$(mktemp -d "/tmp/youtube.XXX")
  mv -v $TMP $BASE
fi

if [[ -z $ID ]]; then
  echo "[ !! ] Missing Id" 1>&2
  exit 1
fi

if [[ $ID =~ ^@ ]]; then
  YOUTUBE_CHANNEL="$YOUTUBE_BASE/$ID/videos"
else
  YOUTUBE_CHANNEL="$YOUTUBE_BASE/channel/$ID/videos"
fi

BASE=$BASE/$ID

if [[ ! -d $BASE ]]; then
  TMP=$(mktemp -d "/tmp/youtube/youtube.XXX")
  mv -v $TMP $BASE
else
  echo "[ !! ] Id was already searched" 1>&2
  ytch_search $BASE/contents.zsv
  exit $?
fi

echo "[ .. ] Downloading webpage" 1>&2
echo "[ == ] Running: $CURL -Ls $YOUTUBE_CHANNEL > $BASE/results.html" 1>&2
$CURL -Ls "$YOUTUBE_CHANNEL" > $BASE/results.html

echo "[ .. ] Carving up the embedded JSON file" 1>&2
echo "[ == ] Running: $GREP  -o 'ytInitialData = {.*};</script>' $BASE/results.html |\
	$SED -e 's:ytInitialData = ::' \
       -e 's:;</script>::' > $BASE/results.json" 1>&2
$GREP  -o 'ytInitialData = {.*};</script>' $BASE/results.html |\
	$SED -e 's:ytInitialData = ::' \
       -e 's:;</script>::' > $BASE/results.json

echo "[ .. ] Querying JSON for contents" 1>&2
echo "[ == ] Running: $JQ [query] $BASE/results.json | sed | awk > $BASE/contents.zsv"
$JQ "$JQUERY" $BASE/results.json |\
  $SED -e 's:^"::' -e 's:"$::'   |\
  $AWK '
BEGIN {
  count = 0;
}
{
  ++count;

  if (count == 5) {
    count = 0;
    print;
  }
  else {
    printf("%s\x00", $0);
  }
}' > $BASE/contents.zsv

ytch_search $BASE/contents.zsv
exit $?
