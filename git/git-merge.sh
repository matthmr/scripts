case $1 in
  '--help'|'-h')
    echo "Usage:       git-merge.sh [OPTIONS] HEAD"
    echo "\
Description: Crudely set the MERGE_HEAD of some current revision to
             \`HEAD'"
    echo "Options:
  -m MESSAGE: commit with MESSAGE
  -e: edit commit message, then commit "
    exit 0 ;;
esac

edit=false

for arg in $@; do
  if [[ ! -z $p_var ]]; then
    eval $p_var=$arg

    p_var=''
  fi

  case $arg in
    -m) p_var=message ;;
    -e) edit=true ;;
    *) HEAD=$arg ;;
  esac
done

if [[ -z $HEAD ]]; then
  echo "[ !! ] Missing HEAD. See \`--help'"
fi

# do_write_merge GITDIR HEAD
function do_write_merge {
  local gitdir=$1
  local merge_branch=$2

  echo "$merge_branch" > $gitdir/MERGE_HEAD

  this_branch=$(git name-rev HEAD | cut -d' ' -f2)
  echo "Merge branch '$merge_branch' into $this_branch" > $gitdir/MERGE_MSG
}

if [[ -d .git ]]; then
  do_write_merge ".git" $HEAD
elif [[ -s .git ]]; then
  do_write_merge "$(cut -d' ' -f2 .git)" $HEAD
fi

if $edit; then
  git merge --continue
elif [[ ! -z $message ]]; then
  git merge -m "$message"
else
  env GIT_EDITOR=true git merge --continue
fi
