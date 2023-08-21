#!/usr/bin/sh

HOOKS_IDX=@HOOKS_TXT@

while read line; do
  if [[ "$line" =~ ^#.*$ || "$line" =~ ^( \t)*$ ]]; then
    continue
  fi

  echo "$line" |
    awk '-F:' '{
    if ($1 != "" && $2 != "") {
      msg="[ == ] HOOK: " $1 ": " $2

      if ($3 != "") {
        msg=msg "\n  -> See:" $3
      }

      print msg
    }
}'
done < "$HOOKS_IDX"
