YT_BASE="https://www.youtube.com"
YT_URL_QUERY="${YT_BASE}/results?search_query="
QUERY="${YT_URL_QUERY}`echo $1 | tr ' ' '+'`"
WATCH_LN=$(curl ${QUERY} | grep -o -Ei '"/watch\?v=[A-Za-z0-9_]+"' | head -1 | cut -d '"' -f 2)
echo "${YT_BASE}${WATCH_LN}"
