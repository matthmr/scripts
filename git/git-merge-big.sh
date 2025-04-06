#!/usr/bin/sh

fetch=@GIT_MERGE_BIG_FETCH_BIG@
set_parent=@GIT_MERGE_BIG_SET_PARENT@

function yes {
  echo -n "[ ?? ] $@ [Y/n] "
  read ans

  if [[ ! -z $ans && $ans != 'y' ]]; then
    echo "[ !! ] Aborting..."
    exit 1
  fi
}

function maybe {
  eval $@

  if [[ $? != 0 ]]; then
    echo "[ !! ] Command failed. Aborting..."
    exit 1
  fi
}

fetch_opts=''
theirs=''

case $1 in
  '--help'|'-h')
    echo "Usage: git-merge-big.sh [OPTIONS] GIT_FETCH_BIG_OPTIONS"
    echo "\
Description: Sets up merging on a big git repository, with the current HEAD as
             ours, and the parent as a 'theirs'-type revision"
    echo "Options:
  -s STAGE: resume from STAGE. Possible values are:

            1. fetch
            2. set_parent
            3. checkout_theirs
            4. merge
            5. reset_theirs
            6. commit
            7. gendiff

            Stages are executed increasingly; this option indicates which one is
            the first to be executed. Default is \`fetch'
  -f OURS: use OURS as OURS, instead of HEAD. Useful when setting STAGE to
           something bigger than \`checkout_theirs'"
    exit 0 ;;
esac

stage=0
head=HEAD

f_var=''
p_var=''

for arg in $@; do
  if [[ ! -z $p_var ]]; then
    if [[ $p_var == 'stage' ]]; then

      case $arg in
        'fetch') stage=0 ;;
        'set_parent') stage=1 ;;
        'checkout_theirs') stage=2 ;;
        'merge') stage=3 ;;
        'reset_theirs') stage=4 ;;
        'gendiff') stage=5 ;;
        *) echo "[ !! ] Invalid value for STAGE. See \`--help'"; exit 1;;
      esac
      p_var=''
      continue
    fi

    eval $p_var="$arg"
    p_var=''

    continue
  fi

  case $arg in
    '-s') p_var=stage ;;
    '-f') p_var=head ;;
    -*) fetch_opts+=" $arg"; f_var="$arg" ;;
    *) fetch_opts+=" $arg"

       # get `theirs' from `-t TAGSPEC' or `-b BRANCHSPEC'
       if [[ $f_var =~ -[tb] ]]; then
         theirs="${arg##*:}"
       fi
       f_var=''
  esac
done

if [[ ! -z $p_var || -z $fetch_opts ]]; then
  echo "[ !! ] Malformed command line. See \`--help'"
  exit 1
fi

ours="$(git rev-parse $head)"
ours_parent="$(git rev-parse $ours^)"
theirs="${theirs:-master}"
theirs_prone=''

echo "[ == ] With:
	OURS: $ours
	BASE: $ours_parent"

# 1. fetch
if [[ $stage -le 0 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: fetch"

  echo "[ .. ] Ensure we're on the latest *merged* version (ours): "
  echo "	-> $(git describe --all --abbrev=0) ($ours)"
  yes "Is this correct? (yes to allow fetch)"
  # yes "About to fetch $theirs. Proceed?"

  echo "[ == ] $fetch $fetch_opts"
  $fetch $fetch_opts

  theirs_rev=$(git rev-parse $theirs)
  echo "[ == ] With:
	THEIRS: $theirs_rev"

  echo "[ OK ] Done"
fi

# verbose messages
if [[ $stage -ge 2 ]]; then
  theirs_prone="remote-$theirs"
  theirs_prone_rev="$(git rev-parse $theirs_prone)"
  echo "[ == ] With:
	THEIRS (prone): $theirs_prone_rev"
elif [[ $stage -ge 1 ]]; then
  theirs_rev=$(git rev-parse $theirs)
  echo "[ == ] With:
	THEIRS: $theirs_rev"
fi

# 2. set_parent
if [[ $stage -le 1 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: set_parent"

  yes "Set parent of $theirs to $ours_parent?"

  echo "[ == ] $set_parent $theirs $ours_parent"
  theirs_prone=$($set_parent $theirs $ours_parent)

  echo "[ OK ] Done. Got $theirs_prone. Prefixing with \`remote-' ..."

  echo "[ == ] git tag remote-$theirs $theirs_prone"
  git tag "remote-$theirs" $theirs_prone

  echo "[ OK ] Done"
fi

# 3. checkout_theirs
if [[ $stage -le 2 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: checkout_theirs"
  yes "Change to $theirs_prone?"

  echo "[ == ] git checkout $theirs_prone"
  git checkout $theirs_prone

  echo "[ OK ] Done"
fi

# 4. merge
if [[ $stage -le 3 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: merge"

  if [[ $stage == 3 ]]; then
    echo "[ .. ] Ensure we're on theirs (proned): "
    echo "	-> $(git describe --all --abbrev=0) ($theirs_prone)"
    yes "Is this correct? (yes to merge $theirs_prone against $ours)"
  else
    yes "Merge $theirs_prone against $ours"
  fi

  echo "[ == ] git merge --no-ff --no-commit $ours"
  git merge --no-ff --no-commit $ours

  if [[ $? != 0 ]]; then
    echo "[ WW ] TREE HAS MERGE CONFLICTS. PLEASE FIX THEM BEFORE CONTINUING."
  fi
fi

# 5. reset_theirs
if [[ $stage -le 4 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: reset_theirs"

  yes "Decapitate merge head?"

  echo "[ == ] rm -v .git/MERGE_HEAD"
  rm -v .git/MERGE_HEAD

  yes "Reset to $theirs?"

  echo "[ == ] git reset --soft $theirs"
  git reset --soft $theirs

  # echo "[ == ] git tag -d remote-$theirs"
  # git tag -d remote-$theirs
fi

# 6. commit
if [[ $stage -le 5 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: commit"

  if [[ $stage == 5 ]]; then
    echo "[ .. ] Ensure we're on theirs: "
    echo "	-> $(git describe --all --abbrev=0) ($theirs)"
    yes "Is this correct? (yes to commit and tag)"
  else
    yes "Commit and tag?"
  fi

  echo "[ == ] git commit -m \"Merge \`$theirs' into mh\""
  git commit -m "Merge \`$theirs' into mh"

  echo "[ == ] git tag mh-$theirs"
  git tag mh-$theirs
fi

# 7. gendiff
if [[ $stage -le 6 ]]; then
  echo -e "\n----------------------------------------\n[ .. ] Stage: gendiff"
  echo "[ OK ] Done. Generating diff at /tmp/diff"

  echo "[ == ] git diff $theirs > /tmp/diff"
  git diff $theirs > /tmp/diff
fi

echo "[ OK ] Done. You can now remove:"
echo "	-> $ours_parent"
echo "	-> $ours"
echo "and run \`git gc --prune=now --aggresive'"
