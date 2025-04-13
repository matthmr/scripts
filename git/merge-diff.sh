#!/bin/sh

# TODO: interactive fzfc version with CSV FILEs?

case $1 in
  '--help'|'-h')
    echo "Usage:       merge-diff.sh [OPTIONS] FILE OURS THEIRS [BASE]"
    echo "\
Description: Displays a diff of successfully merged changes, where
             the file may conflict. No ouput means the merged files is the same
             as OURS. STAGE as OURS or THEIRS uses the current revision's
             staging area"
    echo "Options:
  -k: don't choose \`ours' when merging: it if conflicts, keep it"
    exit 0;;
esac

merge='| choose_ours'

for arg in $@; do
  case $arg in
    '-k') merge='' ;;
    *)
      [[ -z $FILE ]] && FILE=$arg continue
      [[ -z $OURS ]] && OURS=$arg continue
      [[ -z $THEIRS ]] && THEIRS=$arg continue
      [[ -z $BASE ]] && BASE=$arg continue
    ;;
  esac
done

if [[ -z $FILE || -z $OURS || -z $THEIRS ]]; then
  echo "[ !! ] Malformed command line. See \`--help'"
  exit 1
fi

[[ $OURS == STAGE ]] && OURS=''
[[ $THEIRS == STAGE ]] && THEIRS=''
[[ $BASE == STAGE ]] && BASE=''
[[ -z $BASE ]] && BASE=$(git merge-base ${OURS:---octopus} ${THEIRS:---octopus})

ours_id=$(git show $OURS:$FILE | git hash-object -t blob --stdin)
theirs_id=$(git show $THEIRS:$FILE | git hash-object -t blob --stdin)
base_id=$(git show $BASE:$FILE | git hash-object -t blob --stdin)

# choose_ours
function choose_ours {
  awk '
BEGIN {p = 1;}
/^<<<<<<</ {next}
/^\|\|\|\|\|\|\|/ || /^=======/ {p = 0; next}
/^>>>>>>>/ {p = 1; next}
{if (p) print;}'
}

# select the first one as the default in case of merge conflicts
echo "[ == ] git merge-file -p --object-id
	OURS: $ours_id
	BASE: $base_id
	THEIRS: $theirs_id" 1>&2
eval git merge-file -p --object-id $ours_id $base_id $theirs_id $merge \
     > /tmp/.merge

git show $OURS:$FILE | diff -u - /tmp/.merge |\
  sed "s:^\(---\|+++\) \(-\|/tmp/.merge\):\1 $FILE:"

rm /tmp/.merge
