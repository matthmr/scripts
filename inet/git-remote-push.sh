#!/usr/bin/sh

AS=${0##*/}

case $1 in
  '-h'|'--help')
    case $AS in
      'git-remote-push.sh')
        echo "Usage:       git-remote-push.sh OPTIONS... REMOTE [GIT-OPTIONS]"
        echo "Description: Pushes a git repository to the standard remote";;
      'git-remote-pull.sh')
        echo "Usage:       git-remote-pull.sh OPTIONS... REMOTE [GIT-OPTIONS]"
        echo "Description: Pulls a git repository from the standard remote";;
      'git-remote-fetch.sh')
        echo "Usage:       git-remote-fetch.sh OPTIONS... REMOTE [GIT-OPTIONS]"
        echo "Description: Fetches [git options] from the standard remote";;
    esac

    echo "Options:
  -l LOCAL-REPO: use LOCAL-REPO as the local repo, instead of .
  -r REMOTE-REPO: use REMOTE-REPO as the remote repo, instead of LOCAL-REPO"
    exit 0;;
esac

local_repo=''
remote=''
remote_repo=''

for_git=false
git_opt=''

p_var=

for arg in $@; do
  if [[ ! -z $p_var ]]; then
    eval \$p_var=\"$arg\"
    p_var=''
    continue
  fi

  case $arg in
    '-l') p_var=local_repo;;
    '-r') p_var=remote_repo;;
    *)
      if [[ -z $remote ]]; then
        remote=$arg
      else
        git_opt+="$arg "
      fi ;;
 esac
done

if [[ ! -z $p_var ]]; then
  echo "[ !! ] Malformed command line. See \`--help'"
  exit 1
fi

if [[ -z $local_repo ]]; then
  local_repo=.
fi

if [[ -z $remote_repo ]]; then
  repo=$(realpath $local_repo)
  remote_repo=${repo##*/}
fi

if [[ -z $remote ]]; then
  echo "[ !! ] Missing REMOTE"
  exit 1
fi

cmd=
case $AS in
  'git-remote-pull.sh')
    cmd=pull;;
  'git-remote-push.sh')
    cmd=push;;
  'git-remote-fetch.sh')
    cmd=fetch;;
  *)
    echo "[ !! ] Wrong link to \`git-remote-*' command"
    exit 1;;
esac

echo "[ == ] Calling as: git -C $local_repo $cmd git://192.168.$remote/$remote_repo $git_opt"
git -C $local_repo $cmd git://192.168.$remote/$remote_repo $git_opt
