case $1 in
	'-h'|'--help')
		echo "Usage:       get-youtube-link.sh [query]"
		echo "Description: Gets the first youtube link after a \`query'"
		exit 1
esac

YT_BASE="https://www.youtube.com"
YT_URL_QUERY="${YT_BASE}/results?search_query="
QUERY="${YT_URL_QUERY}`echo $1 | tr ' ' '+'`"
WATCH_LN=$(curl ${QUERY} | grep -o -Ei '"/watch\?v=[A-Za-z0-9_]+"' | head -1 | cut -d '"' -f 2)
echo "${YT_BASE}${WATCH_LN}"
