#!/usr/bin/sh

if pidof mpd 2>/dev/null; then
  echo "[ !! ] MPD is already running. Kill it first."
  exit 1
fi

case $1 in
  '--help'|'-h')
    echo "\
Usage:       mpd-server.sh CTL_PORT OUT_PORT"
    echo "\
Description: Run an MPD server with the local IP address, with CTL_PORT as the
             control port, and OUT_PORT as the output port"
    exit 0
    ;;
esac

################################################################################

LOCAL=$(\
  awk '
  /^ {11}\|-- 192\.168\.[0-9]{1,3}\.[^0]/ {
    ifm=$0
    gsub("^ {11}\\|-- ", "", ifm)
    printf("%s", ifm)
    exit
  }' /proc/net/fib_trie)

for arg in $@; do
  if [[ -z $CTL_PORT ]]; then
    CTL_PORT=$arg
  elif [[ -z $OUT_PORT ]]; then
    OUT_PORT=$arg
  fi
done

if [[ -z $CTL_PORT || -z $OUT_PORT ]]; then
   echo "[ !! ] Wrong usage. See \`--help'"
   exit 1
fi

awk -v ctl_port=$CTL_PORT -v out_port=$OUT_PORT -v local=$LOCAL '
/^bind_to_address/ {
  printf("bind_to_address \"%s:%s\"\n", local, ctl_port);
  next;
}
/^audio_output/ {
  printf ("audio_output {\n\
  type            \"httpd\"\n\
  name            \"HTTP Output\"\n\
  encoder         \"lame\"\n\
  bind_to_address \"%s\"\n\
  port            \"%s\"\n\
  quality         \"5.0\"\n\
# bitrate         \"128\"\n\
  format          \"44100:*:2\"\n\
  mixer_type      \"software\"\n\
  max_clients     \"0\"\n\
  always_on       \"yes\"\n\
}\n", local, out_port);
  exit;
}
{
  print;
}
' < @MPD_SERVER_MPD_CONFIG@ > /tmp/mpd.conf

echo "[ .. ] Starting mpd"
mpd --stderr /tmp/mpd.conf

# sleep 1
# echo "[ .. ] Opening HTTP streaming port"
# mpc --host $1 --port 8080 status
