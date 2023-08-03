#!/usr/bin/sh

mkdir -p /tmp/schedl/ 2>/dev/null

JOBS=$(schedl /home/mh/Scripts/job/org.scm 2>/dev/null |\
         sed -n \
             -e '/^JOB:/s/JOB: //p' \
             -e '/^JOB-DO:/s/JOB-DO: /!/p')

file= content= script_content= script=false
echo -e "$JOBS" |\
  while read job; do
    if [[ $job =~ ^! ]]; then
      script=true
      script_content=$(echo $job | sed 's/^!//')
      continue
    fi

    file=/tmp/schedl/$(echo $job | cut -d' ' -f1)
    content=$(echo $job | cut -d' ' -f2-)

    echo "$content" > $file

    if $script; then
      echo "$script_content" > $file.sh
      chmod +x $file.sh
      script=false
    fi
  done
