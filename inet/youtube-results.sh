#!/usr/bin/bash

YOUTUBE_BASE="https://www.youtube.com"
YOUTUBE_QUERY="$YOUTUBE_BASE/results?search_query="
YOUTUBE_WATCH="$YOUTUBE_BASE/watch?v="
BASE=/tmp/youtube

case $1 in
  '-h'|'--help')
    echo "Usage:       ytres \"<query>\" [options]"
    echo "Description: Generates results for an youtube <query>"
    echo "Options:
  -l : list queries
  -w : operation: watch (default)
  -s : operation: show
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
    echo "ytres v2.3.0"
    exit 1;;
esac

if [[ $# -le 0 ]]
then
  echo "[ !! ] Bad usage. See ytres --help" >&2 1>&2
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

OP='watch'
JQUERY=".contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents[] | \
.videoRenderer | \
select(. != null) | \
.title.runs[0].text, \
.videoId, \
.publishedTimeText.simpleText, \
.lengthText.simpleText,
.viewCountText.simpleText, \
.ownerText.runs[0].text, \
.ownerText.runs[0].navigationEndpoint.browseEndpoint.browseId, \
.ownerText.runs[0].navigationEndpoint.browseEndpoint.canonicalBaseUrl"

function ytres_encode {
  echo "$@" | tr ' ' '+'
}

function ytres_load_video {
  echo "[ == ] Running: $MPV $MPV_OPTS $1"
  $MPV $MPV_OPTS "$1"
}

function ytres_search {
  local res=$(
    $AWK -F"\x00" '{printf " %s [%s] [%s] [%s] [%s]\n", $1, $3, $4, $5, $6}' $1 \
      | cat -n | $FZF)

  if [[ -z $res ]]; then
    echo "[ !! ] Ignoring" 1>&2
    exit 1
  fi

  local ln=$(echo "$res" | $AWK '{print $1}')

  case $OP in
    'watch')
      local link=$($AWK -F"\x00" "NR == $ln {print \$2}" $1)
      ytres_load_video "${YOUTUBE_WATCH}${link}";;
    'show')
      $AWK -F"\x00" \
           "NR == $ln {
printf \" -- %s -- \nlink: ${YOUTUBE_WATCH}%s\nuploaded: %s\nduration: %s\n\
views: %s\nby: %s\nid: https://www.youtube.com/channel/%s\n\
handle: https://www.youtube.com%s\n\", \
 \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8}" $1;;
  esac
}

for arg in "$@"; do
  case $arg in
    '-w')
      OP=watch;;
    '-s')
      OP=show;;
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
    '-l')
      if [[ -d $BASE ]]
      then
        find $BASE -type d | sed -n '2,$s:/tmp/youtube/: -> :p'
        exit 1
      else
        echo "[ !! ] No base was found" 1>&2
        exit 1
      fi;;
    *)
      QUERY=$arg;;
  esac
done

if [[ ! -d $BASE ]]; then
  TMP=$(mktemp -d "/tmp/youtube.XXX")
  mv -v $TMP $BASE
fi

if [[ -z $QUERY ]]; then
  echo "[ !! ] Missing query" 1>&2
  exit 1
fi
QUERY=$(ytres_encode $QUERY)
YOUTUBE_QUERY+="$QUERY"
BASE=$BASE/$QUERY

if [[ ! -d $BASE ]]; then
  TMP=$(mktemp -d "/tmp/youtube/youtube.XXX")
  mv -v $TMP $BASE
else
  echo "[ !! ] Query was already searched" 1>&2
  ytres_search $BASE/contents.zsv
  exit $?
fi

echo "[ .. ] Downloading webpage" 1>&2
echo "[ == ] Running: $CURL -Ls $YOUTUBE_QUERY > $BASE/results.html" 1>&2
$CURL -Ls "$YOUTUBE_QUERY" > $BASE/results.html

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

  if (count == 8) {
    count = 0;
    print;
  }
  else {
    printf("%s\x00", $0);
  }
}' > $BASE/contents.zsv

ytres_search $BASE/contents.zsv
exit $?
