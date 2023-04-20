#!/usr/bin/sh

case $1 in
	'-h'|'--help')
		echo "Usage:       sync-cron-like.sh"
		echo "Description: Send locks to tmpfs for \`linux.sh'-like notifications"
		exit 1
		;;
esac

JOBS_FILE=/home/mh/Scripts/job/jobs

function write {
	if [[ ! -d /tmp/cron ]]
	then
		TMP=$(mktemp -d "/tmp/cron.XXX")
		chown -Rv mh:mh $TMP
		chmod -Rv a+w $TMP
		mv -v $TMP /tmp/cron
	fi
	FILE="$1"
	CONTENT="$2"
	echo "$CONTENT" > /tmp/cron/$FILE
}

function script {
	if [[ ! -d /tmp/cron ]]
	then
		TMP=$(mktemp -d "/tmp/cron.XXX")
		chown -Rv mh:mh $TMP
		chmod -Rv a+w $TMP
		mv -v $TMP /tmp/cron
	fi
	FILE="$1"
	CONTENT="$2"
  cp -v $CONTENT /tmp/cron/$FILE.sh
}

CURR_DATE=$(date +%m%d)

__IN_DATE=false
__MATCHES=false

job=
msg=
script=

while read line; do
  if [[ $line =~ ^.+\{ ]]; then
    date=$(echo $line | sed 's/ \+{//g')

    __IN_DATE=true
    __MATCHES=$(expr "$CURR_DATE" : $date)

    if [[ $__MATCHES != '0' ]]; then
      __MATCHES=true
    else
      __MATCHES=false
    fi
    continue
  fi

  if [[ $__IN_DATE ]]; then
    if [[ $line =~ ^.*\} ]]; then
      __IN_DATE=false
    fi

    if $__MATCHES; then
      if ! $__IN_DATE; then
        __MATCHES=false

        job=
        msg=
        script=
        continue
      fi

      job=$(echo $line | cut -f1 -d:)
      msg=$(echo $line | cut -f2 -d:)

      if [[ $(expr "$line" : '^ *@') != '0' ]]; then
        script=$(echo $line | cut -f3 -d@)
      fi

      if [[ ! -z "$script" ]]; then
        job=${job/@/}
        msg=$(echo $msg | sed 's/@.*$//g')
        script "$job" "$script"
      fi

      echo "[ == ] Cron: $job: $msg"

      write "$job" "$msg"

      job=
      msg=
      script=
    fi
  fi
done < "$JOBS_FILE"

echo "[ OK ] sync-cron-like.sh: Done"

exit 0
