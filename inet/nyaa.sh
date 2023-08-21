#!/usr/bin/env bash

case $1 in
  '-h'|'--help')
    echo "Usage:       nyaa.sh [-Ccmtl] [-d <dir>] \"<query>\""
    echo "Description: Queries \`nyaa.si's torrent links to get a magnet link (-m) OR a torrent file (-t),"
    echo "             downloading the torrent to the directory of (-d). Clear queries with (-c) and the"
    echo "             query directory with (-C). Lists entries with (-l)."
    echo "NOTE:        Write the <query> IN QUOTES!. e.g ./nyaa.sh 'neon genesis evangelion'"
    echo "Variables:
    CURL=\`curl'-like command
    XML=\`xml'-like command
    FZF=\`fzf'-like command
    AWK=\`awk'-like command
    TORRENT=\`torrent'-like command"
    exit 1;;
esac

[[ -z $CURL ]]    && CURL='curl'
#[[ -z $XML ]]     && XML='xmllint --html --xpath'
[[ -z $XML ]]     && XML='xml sel -t -v'
[[ -z $FZF ]]     && FZF='fzf'
[[ -z $AWK ]]     && AWK=awk
[[ -z $TORRENT ]] && TORRENT='transmission-remote --trash-torrent'

function query-encode {
  echo "$@" | tr ' ' '+'
}

MODE=magnet

CLEAR=
_CLEAR=0

DIRECTORY=
_DIRECTORY=0

for arg in "$@"; do
  case $arg in
    '-m')
      MODE=magnet;;
    '-t')
      MODE=torrent;;
    '-c')
      _CLEAR=1;;
    '-C')
      if [[ ! -d /tmp/nyaa ]]; then
        echo "[ !! ] Nyaa.sh has no previous instance" 1>&2
      else
        echo "[ !! ] Clearing all" 1>&2
        rm -rfv /tmp/nyaa
      fi
      exit 1;;
    '-d')
      _DIRECTORY=1;;
    '-l')
      if [[ ! -d /tmp/nyaa ]]; then
         echo "[ !! ] Nyaa.sh has no previous instance" 1>&2
      else
        find /tmp/nyaa -type d | sed -n '2,$s:^: -> :p'
      fi
      exit 1;;
    *)
      if [[ $_CLEAR = 1 ]]; then
        CLEAR="$arg"
        _CLEAR=2
      elif [[ $_DIRECTORY = 1 ]]; then
        DIRECTORY="$arg"
        _DIRECTORY=2
      else
        RAW_QUERY="$arg"
      fi;;
  esac
done

if [[ $_CLEAR = 1 ]]; then
    echo "[ !! ] Missing clear target"
    exit 1
elif [[ $_CLEAR = 2 ]]; then
  echo "[ !! ] Clearing target" 1>&2
  if [[ ! -d /tmp/nyaa/$QUERY ]]; then
    echo "[ !! ] Could not find target. Try running \`rm -rfv /tmp/nyaa/<target>" 1>&2
  else
    rm -rfv /tmp/nyaa/$(query-encode $CLEAR)
  fi
  exit 1
elif [[ $_DIRECTORY = 1 ]]; then
  echo "[ !! ] Missing directory target" 1>&2
  exit 1
fi

if [[ -z $RAW_QUERY ]]; then
  echo "[ !! ] Missing query" 1>&2
  exit 1
fi

[[ -z $DIRECTORY ]] && TORRENT_OPT_DOWNLOAD_DIR="--download-dir @NYAA_DIR@" || \
                       TORRENT_OPT_DOWNLOAD_DIR="--download-dir $DIRECTORY"
TORRENT_OPT_ADD_TORRENT="--add"

QUERY=$(query-encode $RAW_QUERY)
NYAA_QUERY="/?q=$QUERY"
NYAA_BASE="https://nyaa.si/"
NYAA="$NYAA_BASE/$NYAA_QUERY"
MKLNK=@NYAA_MKLNK@

# file1: [#] <NAME> <SIZE> <DATE> <SEEDERS> <LEECHERS> <DOWNLOADS>
# file2: [#] <TORRENT> <MAGNET>

# `xmllint`
#XPATH1='//tr/td/a[not(@class) and contains(@href, "/view")]/text() | //tr/td[contains(@class, "text-center")]/text()'
#XPATH2='//tr/td/a[contains(@href, "/download") or contains(@href, "magnet:")]/@href'

# `xml` aka `xmlstarlet`
XPATH1='/tbody/tr/td/a[not(@class) and contains(@href, "/view")] | /tbody/tr/td[contains(@class, "text-center")]'
XPATH2='/tbody/tr/td/a[contains(@href, "/download") or contains(@href, "magnet:")]/@href'

function download {
  echo "[ .. ] Dowloading page" 1>&2
  $CURL -s "$NYAA" 2>/dev/null 1>/tmp/nyaa/$QUERY/$QUERY.html

  echo "[ .. ] Extracting table"
  $AWK '
  BEGIN       {table=0}
  /<tbody>/   {table=1}
  /<\/tbody>/ {table=-1}
  {if (table == 1) {
     print
   }
   else if (table == -1) {
     print
     exit
  }}' /tmp/nyaa/$QUERY/$QUERY.html |\
      sed "s:\(<img.*\?\)\(>\):\1></img>:g" > /tmp/nyaa/$QUERY/$QUERY-tab.xml
      # ^^ dirty little hack to make the ONLY FUCKING XML PARSER THAT I GOT WORKING working :)

  echo "[1/2 ] Parsing HTML" 1>&2
  $XML "$XPATH1" /tmp/nyaa/$QUERY/$QUERY-tab.xml |\
    $MKLNK -v x=1 > /tmp/nyaa/$QUERY/$QUERY-x1.txt

  echo "[2/2 ] Parsing HTML" 1>&2
  # add this as a output pipe for the command below if using `xmllint`
  #| sed -e 's: href=::' -e 's:"::g' |\
  $XML "$XPATH2" /tmp/nyaa/$QUERY/$QUERY-tab.xml |\
    $MKLNK -v x=2 > /tmp/nyaa/$QUERY/$QUERY-x2.txt

  echo "[ OK ] Done" 1>&2
}

if [[ -d /tmp/nyaa ]]; then
  if [[ -d /tmp/nyaa/$QUERY ]]; then
    echo "[ WW ] Query was already searched. reading from disk..." 1>&2
  else
    mkdir /tmp/nyaa/$QUERY
    download
  fi
else
  mkdir /tmp/nyaa
  mkdir /tmp/nyaa/$QUERY
  download
fi

while :; do
  read -p "Operation ([c]hoose, [r]ank, [d]ownload, [q]uit): " ans1
  case $ans1 in
    'c')
      CHOSEN=$(cat /tmp/nyaa/$QUERY/$QUERY-x1.txt | $FZF)

      if [[ -z $CHOSEN ]]; then
        echo "[ !! ] Aborting"
        exit 1
      else
        N=$(echo "$CHOSEN" | awk '{print $1}')
        case $MODE in
          'magnet')
            _TORRENT=$(sed -n "${N}p" /tmp/nyaa/$QUERY/$QUERY-x2.txt | awk '{print $3}');;
          'torrent')
            if [[ -f /tmp/nyaa/$QUERY/$QUERY.torrent ]]; then
              echo "[ WW ] Found previous torrent file. Consider removing it" 1>&2
              exit 1
            fi
            _TORRENT=$(sed -n "${N}p" /tmp/nyaa/$QUERY/$QUERY-x2.txt | awk '{print $2}')
            $CURL -s "$NYAA_BASE/$_TORRENT" 1>/tmp/nyaa/$QUERY/$QUERY.torrent 2>/dev/null
            _TORRENT=/tmp/nyaa/$QUERY/$QUERY.torrent;;
        esac
      fi
      $TORRENT $TORRENT_OPT_DOWNLOAD_DIR $TORRENT_OPT_ADD_TORRENT $_TORRENT
      break;;
    'r')
      while :; do
        read -p "Sort (si[z]e, [s]eeders, [l]eechers, [d]ownloads, [q]uit): " ans2
        case $ans2 in
          'z')
            $AWK '{print $(NF-6)$(NF-5),$0}' /tmp/nyaa/$QUERY/$QUERY-x1.txt | sort -h -k1,2;;
          's')
            $AWK '{print $(NF-2),$0}' /tmp/nyaa/$QUERY/$QUERY-x1.txt        | sort -k1,1n;;
          'l')
            $AWK '{print $(NF-1),$0}' /tmp/nyaa/$QUERY/$QUERY-x1.txt        | sort -k1,1n;;
          'd')
            $AWK '{print $NF,$0}' /tmp/nyaa/$QUERY/$QUERY-x1.txt            | sort -k1,1n;;
          'q')
            break;;
          *)
            echo "[ !! ] Invalid" 1>&2;;
        esac
      done
      ;;
    'd')
      download;;
    'q')
      break;;
    *)
      echo "[ !! ] Invalid" 1>&2;;
  esac
done
