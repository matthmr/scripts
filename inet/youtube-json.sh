#!/usr/bin/env bash

# Integrated by mH (https://github.com/matthmr)

#*****************************************************
# change anything that is followed by "#change this" #
#*****************************************************

# youtube-json.sh [-c:clear query,-l:list queries] <query>

YOUTUBE_BASE="https://www.youtube.com"
YOUTUBE_QUERY="$YOUTUBE_BASE/results?search_query="
YOUTUBE_WATCH="$YOUTUBE_BASE/watch?v="
AWK_BASE=/home/mh/Scripts/inet #change this
YTDOWNLOAD=yt-dlp #change this
BASE=/tmp/youtube

case $1 in
	'-c')
		if [[ -d $BASE ]]
		then
			rm -rfv $BASE
			exit 1
		else
			echo "[ !! ] No base was found"
			exit 1
		fi;;
	'-l')
		if [[ -d $BASE ]]
		then
			find $BASE -type d | sed 1d
			exit 1
		else
			echo "[ !! ] No base was found"
			exit 1
		fi;;
	'-h'|'--help')
		echo "Usage:       youtube-json.sh [-c:clear query] <query>"
		echo "Description: Generates a static, w3m-viewable webpage with the youtube results of <query>"
		echo "Variables:
	JQ : jq-like command
	CURL : curl-like command
	GREP : grep-like command
	SED : sed-like command"
		exit 1
esac

if [[ $# -le 0 ]]
then
	echo "[ !! ] Bad usage. See youtube-json.sh --help" >&2
	exit 1
fi

[[ -z $CURL ]] && CURL=/bin/curl
[[ -z $GREP ]] && GREP=/bin/grep
[[ -z $SED ]] &&  SED=/bin/sed
[[ -z $JQ ]] && JQ=jq

function encode {
	echo "$@" | tr ' ' '+'
}

echo "[ .. ] Setting up the static website"
QUERY=$(encode "$1")
if [[ ! -d $BASE ]]
then
	TMP=$(mktemp -d "/tmp/youtube.XXX")
	mv -v $TMP $BASE
fi

TMP=$(mktemp -d "/tmp/youtube/youtube.XXX")
mv -v $TMP $BASE/$QUERY
BASE=$BASE/$QUERY

echo "[ INFO ] query: \`$QUERY'"
PAGE="$YOUTUBE_QUERY$(encode "$QUERY")"
echo "[ INFO ] downlading page: \`$PAGE'"
echo "[ .. ] Downloading webpage"
$CURL -s "$YOUTUBE_QUERY/$(encode "$QUERY")" \
	> $BASE/results.html

echo "[ .. ] Carving up the embedded JSON file"
$GREP -Po \
	'ytInitialData = {.*};</script>' \
	$BASE/results.html |\
	$SED -E 's/^ytInitialData = |;<\/script>$//g' > \
		$BASE/results.json

echo "[ .. ] Querying JSON for contents"
$JQ -cM \
	'.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents' \
	$BASE/results.json > $BASE/contents.json

echo "[ .. ] Querying JSON for video info"
QUERY=$($JQ -cM \
	".[].videoRenderer | \
select(. != null) | \
.videoId, \
.title.runs[0].text, .lengthText.simpleText, \
.ownerText.runs[0].navigationEndpoint.commandMetadata.webCommandMetadata.url, \
.ownerText.runs[0].text, .publishedTimeText.simpleText, .shortViewCountText.simpleText, \
.thumbnail.thumbnails[0].url, \
.channelThumbnailSupportedRenderers.channelThumbnailWithLinkRenderer.thumbnail.thumbnails[0].url" \
	$BASE/contents.json | tr -d '"')
echo "$QUERY" | sed -E 's/https?:.*//g' > $BASE/query.txt
echo "$QUERY" | grep -Eo 'https?:.*' > $BASE/links.txt

echo "[ .. ] Dowloading assets"
#TODO: make this optional as it uses quite a lot of resources
m=0
n=1
while read link
do
	if [[ $m -le 0 ]]
	then
		echo "[ .. ] Downloading video thumbnail $n/20"
		$CURL -s "$link" > $BASE/"t$n".jpg
		m=1
	else
		echo "[ .. ] Downloading channel icon $n/20"
		$CURL -s "$link" > $BASE/"c$n".jpg
		m=0
		n=$((n+1))
	fi
done < $BASE/links.txt

echo "[ .. ] Making the HTML page"
$AWK_BASE/youtube-json.awk \
	-vBASE="$BASE" \
	$BASE/query.txt > $BASE/index.html

echo "[ OK ] Done!"
