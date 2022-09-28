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

function encode {
	echo "$@" | tr ' ' '+'
}

static=n
JQUERY=".[].videoRenderer | \
select(. != null) | \
.title.runs[0].text, .lengthText.simpleText, \
.ownerText.runs[0].text, .publishedTimeText.simpleText, .shortViewCountText.simpleText, \
.videoId"
case $1 in
	'-s')
		JQUERY=".[].videoRenderer | \
select(. != null) | \
.videoId, \
.title.runs[0].text, .lengthText.simpleText, \
.ownerText.runs[0].navigationEndpoint.commandMetadata.webCommandMetadata.url, \
.ownerText.runs[0].text, .publishedTimeText.simpleText, .shortViewCountText.simpleText, \
.thumbnail.thumbnails[0].url, \
.channelThumbnailSupportedRenderers.channelThumbnailWithLinkRenderer.thumbnail.thumbnails[0].url"
		static=y;;
	'-c')
		if [[ -d $BASE ]]
		then

			if [[ $# = 2 ]]
			then
				_query="$BASE/$(encode $2)"
				if [[ -d "$_query" ]]
				then
					echo "[ .. ] Removing \`$_query'..." 1>&2
					rm -rfv "$_query"
					exit 0
				else
					echo "[ !! ] No such query \`$_query' was found" 1>&2
					exit 1
				fi
			fi

			rm -rfv $BASE
			exit 0
		else
			echo "[ !! ] No base was found" 1>&2
			exit 1
		fi;;
	'-l')
		if [[ -d $BASE ]]
		then
			find $BASE -type d | sed 1d | sed 's/\/tmp\/youtube\// -> /g'
			exit 1
		else
			echo "[ !! ] No base was found" 1>&2
			exit 1
		fi;;
	'-h'|'--help')
		echo "Usage:       ytres [-c:clear <query>] [-s:static webpage] \"<query>\""
		echo "Description: Generates a static, w3m-viewable webpage with the youtube results of <query> or a simple formated output"
		echo "Variables:
	JQ : jq-like command
	CURL : curl-like command
	GREP : grep-like command
	SED : sed-like command"
		exit 1;;
	'-v'|'--version')
		echo "ytres v1.0.0"
		exit 1;;
esac

if [[ $# -le 0 ]]
then
	echo "[ !! ] Bad usage. See ytres --help" >&2 1>&2
	exit 1
fi

[[ -z $CURL ]] && CURL=/bin/curl
[[ -z $GREP ]] && GREP=/bin/grep
[[ -z $SED ]] &&  SED=/bin/sed
[[ -z $JQ ]] &&   JQ=jq

echo "[ .. ] Setting up the static website" 1>&2
if [[ $static = 'n' ]]
then
	QUERY=$(encode "$1")
else
	QUERY=$(encode "$2")
fi

if [[ -d $BASE/$QUERY ]]
then
	BASE=$BASE/$QUERY
	echo "[ !! ] The query \`$QUERY' was already searched" 1>&2

	if [[ $static = 'y' ]]
	then
		exit 1
	fi

	if [[ -f $BASE/query.txt ]]
	then

		if [[ -f $BASE/index.html ]] # then convert
		then
			if [[ -f $BASE/_query.txt ]] # already converted
			then
				echo "[ !! ] Previous conversion found" 1>&2
				cat $BASE/_query.txt
				exit 0
			else
				echo "[ !! ] The query \`$QUERY' was statically generated. Converting it back..." 1>&2
				$SED -E 's/\/(c|channel|user)\/.*//g' $BASE/query.txt |\
					$AWK_BASE/youtube-json-convert.awk > $BASE/_query.txt
				cat $BASE/_query.txt
				exit 0
			fi
		fi

		echo "[ .. ] Outputing results" 1>&2
		$AWK_BASE/youtube-json.awk \
			-vBASE="$BASE" -vstatic=$static \
			$BASE/query.txt
	else
		echo "[ !! ] No \`query.txt' file was found for \`$BASE/$QUERY'. youtube-json is probably broken, it is best to run \`youtube-json.sh -c'" 1>&2
		exit 1
	fi

	exit 0
fi

if [[ ! -d $BASE ]]
then
	TMP=$(mktemp -d "/tmp/youtube.XXX")
	mv -v $TMP $BASE
fi

TMP=$(mktemp -d "/tmp/youtube/youtube.XXX")
mv -v $TMP $BASE/$QUERY
BASE=$BASE/$QUERY

echo "[ INFO ] query: \`$QUERY'" 1>&2
PAGE="$YOUTUBE_QUERY$(encode "$QUERY")"
echo "[ INFO ] downlading page: \`$PAGE'" 1>&2
echo "[ .. ] Downloading webpage" 1>&2
$CURL -s "$YOUTUBE_QUERY/$(encode "$QUERY")" \
	> $BASE/results.html

echo "[ .. ] Carving up the embedded JSON file" 1>&2
$GREP -Po \
	'ytInitialData = {.*};</script>' \
	$BASE/results.html |\
	$SED -E 's/^ytInitialData = |;<\/script>$//g' > \
		$BASE/results.json

echo "[ .. ] Querying JSON for contents" 1>&2
$JQ -cM \
	'.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents' \
	$BASE/results.json > $BASE/contents.json

echo "[ .. ] Querying JSON for video info" 1>&2
QUERY=$($JQ -cM "$JQUERY" $BASE/contents.json | tr -d '"')
echo "$QUERY" | sed -E 's/https?:.*//g' > $BASE/query.txt

if [[ $static = 'y' ]]
then
	echo "$QUERY" | grep -Eo 'https?:.*' > $BASE/links.txt

	echo "[ .. ] Dowloading assets" 1>&2
	m=0
	n=1
	while read link
	do
		if [[ $m -le 0 ]]
		then
			echo "[ .. ] Downloading video thumbnail $n/20" 1>&2
			$CURL -s "$link" > $BASE/"t$n".jpg
			m=1
		else
			echo "[ .. ] Downloading channel icon $n/20" 1>&2
			$CURL -s "$link" > $BASE/"c$n".jpg
			m=0
			n=$((n+1))
		fi
	done < $BASE/links.txt

	echo "[ .. ] Making the HTML page" 1>&2
	$AWK_BASE/youtube-json.awk \
		-vBASE="$BASE" -vstatic=$static \
		$BASE/query.txt > $BASE/index.html
else
	echo "[ .. ] Outputing results" 1>&2
	$AWK_BASE/youtube-json.awk \
		-vBASE="$BASE" -vstatic=$static \
		$BASE/query.txt
fi

echo "[ OK ] Done!" 1>&2
