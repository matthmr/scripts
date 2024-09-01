#!/usr/bin/sh

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

####

if [[ ! -f /tmp/schedl/schedl-run ]]; then
  touch /tmp/schedl/schedl-run

  for file in $@; do
    op $file
  done
fi

####

echo "[ == ] Prompting for execution"

while read job; do
  # we have to execute this in a different script so that C-c doesn't kill us
  /home/p/scripts/job/schedl-run.sh $job
done < /tmp/schedl/schedl-run

# rm /tmp/schedl/schedl-run
