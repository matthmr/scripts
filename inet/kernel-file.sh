#!/usr/bin/bash

case $1 in
  '-h'|'--help')
    echo "Usage:       kernel-file.sh [-l] <file>"
    echo "Description: Echo remote kernel source file to stdout"
    echo "Options:
    -l <file> :: runs a list command on a given directory."
    echo "Variables:
    CURL=\`curl'-like command
    XML=\`xmlstarlet'-like command
    AWK=\`awk'-like command
    SED=\`sed'-like command"
    exit 1;;
esac

[[ -z $CURL ]] && CURL='curl'
[[ -z $XML ]]  && XML='xml sel -t -v'
[[ -z $AWK ]]  && AWK='awk'
[[ -z $SED ]]  && SED='sed'

XQUERY="/html/body/ul/li/a/@href"

KERNEL_ORG_SRV="https://git.kernel.org"
KERNEL_ORG_ROUTE="pub/scm/linux/kernel/git/torvalds/linux.git/plain"
KERNEL_ORG_PLAIN="${KERNEL_ORG_SRV}/${KERNEL_ORG_ROUTE}"

function maybefile {
  if [[ -z $1 ]]; then
    echo "[ !! ] Missing file"
    exit 1
  else
    FILE=$1
  fi
}

function correctfile {
  FILE=$(echo "${FILE}" | $SED 's:\./::g;s:/\{2,\}:/:g')
}

case $1 in
  '-l')
    FILE=$2
    correctfile "${FILE}"
    if [[ ! ${FILE} =~ \/$ ]]; then
      [[ ! -z ${FILE} ]] && FILE="${FILE#/}/"
    fi
    URL="${KERNEL_ORG_PLAIN}/${FILE}"
    $CURL -s "${URL}" |\
      $XML $XQUERY |\
      $AWK '
/\/$/ {
  printf "-> %s\n", $0;
}
/[^\/]$/ {
  printf "** %s\n", $0;
}' | $SED -e "s:/${KERNEL_ORG_ROUTE/./\\.}/${FILE}::"\
          -e "s:/${KERNEL_ORG_ROUTE/./\\.}/:../:"
    ;;
  *)
    maybefile $1
    correctfile "${FILE}"
    URL="${KERNEL_ORG_PLAIN}/${FILE}"
    $CURL -s "${URL}" |\
      $AWK '
NR == 1 {
  if ($0 ~ /^<!DOCTYPE html>$/) {
    print "[ !! ] File does not exist"
    exit
  }
  if ($0 ~ /<html>/) {
    print "[ !! ] File is a directory"
    exit
  }
}
{
  print
}
';;
esac
