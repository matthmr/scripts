#!/usr/bin/sh

# TODO: add `init' capability

case $1 in
  '--help'|'-h')
    echo "Usage:       git-fetch-big.sh [OPTIONS]"
    echo "Description: git-fetch(1) for big repositories"
    echo "Options:
  -o ORIGIN: use ORIGIN as origin. default is \`origin'
  -T: don't ignore tags
  -b BRANCHSPEC...: fetch BRANCHSPEC... if empty, fetch master:master
  -t TAGSPEC...: fetch TAGSPEC..."
    exit 0 ;;
esac

p_var=''

origin=''
branch=''

git_fetch_opts=-pufn

for arg in $@; do
  if [[ ! -z $p_var ]]; then
    case $p_var in
      'origin') origin=$arg ;;

      'branch')
        if [[ ! $arg =~ : ]]; then
          branch+="$arg:$arg "
        else
          branch+="$arg "
        fi ;;

      'tag')
        if [[ ! $arg =~ : ]]; then
          arg="refs/tags/$arg"
          branch+="$arg:$arg "
        else
          ours="refs/tags/${arg##*:}"
          theirs="refs/tags/${arg%%:*}"
          branch+="$theirs:$ours "
        fi ;;
    esac

    p_var=''
    continue
  fi

  case $arg in
    '-o') p_var=origin ;;
    '-b') p_var=branch ;;
    '-t') p_var=tag ;;
    '-T') git_fetch_opts="${git_fetch_opts/n/}" ;;
    *) echo "[ !! ] Unknown option. See \`--help'"; exit 1 ;;
  esac
done

if [[ ! -z $p_var ]]; then
  echo "[ !! ] Pending option. See \`--help'"
  exit 1
fi

origin=${origin:-origin}
branch=${branch:-master:master}

echo "[ .. ] Running: git fetch $git_fetch_opts --depth=1 $origin -- $branch"

git fetch $git_fetch_opts --depth=1 $origin -- $branch

if [[ $? != 0 ]]; then
  echo "[ !! ] git-fetch erroed. Exiting..."
  exit 1
fi

checked=$(git rev-parse HEAD)

for ref in $branch; do
  ref=${ref##*:}

  if [[ "$(git rev-parse $ref 2>/dev/null)" == "$checked" ]]; then
    echo -n "[ ?? ] Fetched ref ($ref) is already checked out, clear \
working directory? [Y/n] "
    read ans

    if [[ -z $ans || $ans == 'y' ]]; then
      git restore -SW -- .
    fi
  fi
done
