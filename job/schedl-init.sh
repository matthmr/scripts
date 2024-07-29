#!/usr/bin/sh

printf '' > /tmp/schedl/schedl-run

function op {
  local file=$file

  while read jobfile; do
    if [[ $jobfile =~ ^#.*$ || $jobfile =~ ^( \t)*$ ]]; then
      continue
    fi

    echo "[ == ] On file \`$jobfile':"
    schedl -i $jobfile < /dev/tty 2>>/tmp/schedl/schedl.log

    # only flag the 'runnable' jobs. message jobs will be shown on terminal
    # output, because we're invoking `schedl' with `-i'
    sed -n -e '/^JOB:/s/JOB: //p' -e '/^DO:/s/DO: /!/p' /tmp/schedl/schedl-out \
    | while read job; do
      [[ $job =~ ^$ ]] && continue

      # DO:
      if [[ $job =~ ^! ]]; then
        jobfile="$jobfile.sh"
        echo "$jobfile" >> /tmp/schedl/schedl-run
        echo "$job" | sed 's/^!//' > $jobfile
        chmod +x $jobfile

        continue
      fi

      # JOB:
      jobfile=/tmp/schedl/$(echo $job | cut -d' ' -f1)
    done

    cat /tmp/schedl/schedl-out >> /tmp/schedl/schedl.log
  done < $file

  rm /tmp/schedl/schedl-out
}

function run {
  local job=$1
  local timeout=2

  echo -n "[ ?? ] Run \`$job'? [Y/n] "
  read ans

  if [[ ! -z $ans && $ans != 'y' ]]; then
    echo "[ !! ] Ignoring ..."
  else
    echo "[ .. ] Executing \`$job'. Press C-c to cancel..."
    sleep $timeout
    $job
  fi
}

####

for file in $@; do
  op $file
done

####

echo "[ == ] Prompting for execution"

while read job; do
  run $job < /dev/tty
done < /tmp/schedl/schedl-run

rm /tmp/schedl/schedl-run
