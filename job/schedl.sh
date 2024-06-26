#!/usr/bin/sh

file= content= script_content= script=false
while read jobfile; do
  if [[ $jobfile =~ ^#.*$ || $jobfile =~ ^( \t)*$ ]]; then
    continue
  fi

  schedl $jobfile 2>>/tmp/schedl/schedl.log \
  | sed -n \
        -e '/^JOB:/s/JOB: //p' \
        -e '/^DO:/s/DO: /!/p'\
  | while read job; do
    [[ $job =~ ^$ ]] && continue

    if [[ $job =~ ^! ]]; then
      script=true
      script_content=$(echo $job | sed 's/^!//')
      continue
    fi

    filename=$(echo $job | cut -d' ' -f1)
    content=$(echo $job | cut -d' ' -f2-)
    file=/tmp/schedl/$filename

    echo "$content" > $file

    if $script; then
      echo "$script_content" > $file.sh
      chmod +x $file.sh
      script=false
    fi
  done
done < @SCHEDL_TXT@
