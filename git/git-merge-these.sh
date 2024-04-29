#!/usr/bin/bash

case $1 in
  '--help'|'-h')
    echo "Usage:       git-merge-these.sh [OPTIONS] THEIRS [BASE]"
    echo "Description: Operate in files changed in the merge/cherry with THEIRS,
  or future merge/cherry from OURS, with an optional merge base BASE"
    echo "Options:
  -i: run interactively
  -k: ignore renames
  -R: reverse THEIRS and OURS
  -o OURS: use OURS as OURS, instead of HEAD
  -w: write index of HEAD as THEIRS/BASE. Will exit the script
  -m HEAD: write the merge head as HEAD. Will exit the script
  -r[otb]: read from index as OURS/THEIRS/BASE"
    echo "Environment:
  MERGE_EDITOR: use this editor, instead of emacsclient -t"
    exit 0;;
esac

SHELL=sh

theirs=""
ours=""
base=""

out=""

p_val=""
merge_branch=""

interactive=false
reverse=false

write_index=false
read_index=""

diff_opts=""

[[ -z $MERGE_EDITOR ]] && editor='emacsclient -t' || editor=$MERGE_EDITOR

for arg in $@; do
  if [[ ! -z $p_val ]]; then
    eval $p_val=$arg

    p_val=""
    continue
  fi

  case $arg in
    '-i') interactive=true ;;
    '-o') p_val="ours" ;;

    '-ro') read_index="ours" ;;
    '-rt') read_index="theirs" ;;
    '-rb') read_index="base" ;;

    '-w') write_index=true ;;
    '-m') p_val="merge_branch" ;;
    '-k') diff_opts="--no-renames" ;;

    '-R') reverse=true ;;

    *)
      if [[ -z $theirs ]]; then
        theirs=$arg
      elif [[ -z $base ]]; then
        base=$arg
      else
        echo "[ !! ] Malformed command line. See \`--help'"
        exit 1
      fi
  esac
done

if [[ ! -z $p_val ]]; then
  echo "[ !! ] Malformed option. See \`--help'"
fi

if $write_index; then
  ref=$(git write-tree)
  echo "[ .. ] Writing: $ref"
  echo $ref > /tmp/.gitidx

  exit 0
fi

# do_write_merge GITDIR
function do_write_merge {
  local gitdir=$1

  rm $gitdir/MERGE_HEAD 2>/dev/null
  echo "$theirs" > $gitdir/MERGE_HEAD

  this_branch=$(git branch | awk '/\*/ {print $2}')
  echo "Merge branch '$merge_branch' into $this_branch" > $gitdir/MERGE_MSG
}

if [[ ! -z $merge_branch ]]; then
  if [[ -d .git ]]; then
    do_write_merge ".git"
  elif [[ -s .git ]]; then
    do_write_merge "$(cut -d' ' -f2 .git)"
  fi

  exit 0
fi

case $read_index in
  "ours")
    if [[ -z $ours ]]; then
      ours=$(cat /tmp/.gitidx 2>/dev/null)
    else
      echo "[ WW ] Skip index read, because OURS is set"
    fi ;;

  "theirs")
    if [[ "$theirs" == '.' ]]; then
      theirs=$(cat /tmp/.gitidx 2>/dev/null)
    else
      echo "[ WW ] Skip index read, because THEIRS is set"
    fi ;;

  "base")
    if [[ -z $base ]]; then
      base=$(cat /tmp/.gitidx 2>/dev/null)
    else
      echo "[ WW ] Skip index read, because BASE is set"
    fi ;;
esac

if [[ -z $ours ]]; then
  ours=HEAD
fi

if [[ -z $theirs ]]; then
  echo "[ !! ] Missing THEIRS. See \`--help'"
  exit 1
fi

if [[ -z $base ]]; then
  base=$(git merge-base $ours $theirs)
fi

if $reverse; then
  _ours=$ours

  ours=$theirs
  theirs=$_ours
fi

################################################################################

function flatten {
  echo $@ | tr '\n' ' '
}

# ediff FILE
function ediff {
  local file=$(realpath $1)
  local base=$base

  emacsclient -e \
    "(progn (require 'ediff-vers)
            (find-file \"$file\")
            (ediff-vc-merge-internal
              \"$ours\" \"$theirs\" \"$base\" nil \"$file\"))"
}

# with_editor EDITOR FILES...
function with_editor {
  local editor=$1

  names=""

  while read file rest; do
    names+="$file "
  done < <(echo "${@:2}")

  for file in $names; do
    if [[ $file =~ '--' ]]; then
      continue
    fi

    printf "[ ?? ] Edit this file: $file [Y/n/q] "
    read ans

    case $ans in
      ''|'y') $editor $file ;;
      'q') return ;;
      *) echo "[ .. ] Ignoring" ;;
    esac
  done
}

# fzf_with_prompt PROMPT CMD
function fzf_with_prompt {
  local prompt=$1
  local cmd=$2

  fzf -m --prompt "$prompt" --preview "$cmd" --height 40
}

################################################################################

# git_diff_inc
function git_diff_inc {
  git -P diff --raw --cc --combined-all-paths $diff_opts \
    $theirs $base $ours -- | tr '\t' ' '
}

# git_flag_merge_conflict SAFE CONFLICT LIST...
function git_flag_merge_conflict {
  local safe=$1
  local conflict=$2

  NL=$'\n'

  while read theirs_name theirs_mod ours_name ours_id base_id theirs_id; do
    [[ -z $theirs_name ]] && break

    line="$theirs_name $theirs_mod $ours_name $ours_id $base_id $theirs_id$NL"

    git merge-file -p --object-id $ours_id $base_id $theirs_id |\
       grep -q '^<<<<<<<'

    if [[ $? == '0' ]]; then
      eval "$conflict+=\"$line\""
    else
      eval "$safe+=\"$line\""
    fi
  done < <(echo "${@:3}")
}

# git_checkout_file LIST...
function git_checkout_file {
  echo "$@" | while read theirs_name theirs_id theirs_mod ours_name; do
    # if a directory exists with the same name, this would automatically
    # conflict, so we have to handle it
    if [[ -d $ours_name ]]; then
      echo -n "[ ?? ] A directory exists in \`ours' with the same name as
  \`$ours_name'. What to do? [new name|(q)uit|(!)shell] "

      read ans

      case $ans in
        ''|'q') continue ;;
        '!') $SHELL ;;
        *) git show $theirs_id > $ans; chmod -hv ${theirs_mod:2} $ans ;;
      esac
    else
      git checkout $theirs -- $theirs_name
    fi
  done
}

# git_remove_file LIST...
function git_remove_file {
  echo "$@" | while read theirs_name ours_name; do
    git rm -f $theirs_name
  done
}

# git_merge_file LIST...
function git_merge_file {
  echo "$@" | while read theirs_name theirs_mod ours_name ours_id base_id theirs_id; do
    oid=$(git merge-file --object-id $ours_id $base_id $theirs_id)
    git update-index --verbose --replace --add --remove --cacheinfo $theirs_mod $oid $theirs_name
    git restore $theirs_name
  done
}

# git_merge_file_and_add LIST...
function git_merge_file_and_add {
  echo "$@" | while read theirs_name theirs_mod ours_name ours_id base_id theirs_id; do
    git merge-file -p --object-id $ours_id $base_id $theirs_id > $theirs_name
    chmod -hv ${theirs_mod:2} $theirs_name
    git add $theirs_name
  done
}

# git_with_prompt CMD PREVIEWCMD EDITCMD PROMPT ACTION OURS...
function git_with_prompt {
  local cmd=$1
  local fzfcmd=$2
  local editcmd=$3
  local prompt=$4
  local action=$5
  local list="$(echo "$6" | sed '/^$/d')"

  local choose=""

  local initcmd=$cmd

  case $action in
    'a'|'o') choose="$list";;
    'e') choose="$list"; cmd="with_editor $editcmd";;
    'A'|'O') choose="$(echo "$list" | fzf_with_prompt "$prompt" "$fzfcmd")";;
    'E') choose="$(echo "$list" | fzf_with_prompt "$prompt" "$fzfcmd")"; cmd="with_editor $editcmd";;
  esac

  if [[ ! -z $choose ]]; then
    if [[ "$initcmd" == "false" && -z $cmd ]]; then
      echo "[ !! ] This option does not support any automatic action"
      return 1
    fi

    echo "[ .. ] Running: $cmd"

    if [[ $action =~ [Oo] ]]; then
      out+="$(echo "$choose" | awk '{printf("%s ", $1)}')"
    else
      eval "$cmd \"$choose\""
    fi
  fi
}

################################################################################

choose_prompt="
  Quit (q)
  Force quit (Q)
  Shell (!)"
choose_avail=""

# choose_add PROMPT OPTION
function choose_add {
  local prompt=$1
  local option=$2

  choose_prompt+="
  $prompt ($option)"
  choose_avail+="$option|"
}

checkout_show=""
checkout_diff=""
checkout_diff3=""
checkout_diff_name=""
checkout_diff_ours=""
remove=""
merge_diff=""
rename_both=""
mod_both=""
rename_mod=""

echo "[ == ] With:
  OURS: $(git rev-parse $ours)
  THEIRS: $(git rev-parse $theirs)
  BASE: $(git rev-parse $base)
"

echo "[ == ] git output (base/ours->theirs), (base -> theirs):"

NL=$'\n'

# ::100644 100644 100755 c5f24d6 c5f24d6 c5f24d6 MM Makefile Makefile Makefile
while read base_mod ours_mod theirs_mod \
           base_id ours_id theirs_id \
           base_ours_stat \
           base_name ours_name theirs_name; do
  base_mod="${base_mod#::}"

  echo "  $base_ours_stat $ours_mod $ours_name~$ours_id -> \
$theirs_mod $theirs_name~$theirs_id"

  case $base_ours_stat in
    # with checkout
    AA|TT|TA) checkout_show+="$theirs_name $theirs_id $theirs_mod$NL";;
    MA) checkout_diff+="$theirs_name $theirs_id $theirs_mod$NL";;
    MT) checkout_diff3+="$theirs_name $theirs_id $theirs_mod$NL";;
    AT) checkout_diff_ours+="$theirs_name $theirs_id $theirs_mod $ours_name$NL";;

    # with remove
    DD) remove+="$theirs_name $theirs_name$NL";;

    # with merge
    TM|AM) merge_diff+="$theirs_name $theirs_mod $ours_name $ours_id $base_id $theirs_id$NL";;
    MM) mod_both+="$theirs_name $theirs_mod $ours_name $ours_id $base_id $theirs_id$NL";;

    # TODO: implement rename
    # RA) checkout_diff_name+="$theirs_name $base_id $theirs_id$NL";;
    # RT) checkout_diff3_name+="$";;
    # RR) rename_both+="$theirs_name$NL";;
    # RM) rename_mod+="$theirs_name$NL";;
  esac
done < <(git_diff_inc)

echo ""

[[ ! -z $checkout_show ]] && choose_add "Checkout (show)" "cs"
[[ ! -z $checkout_diff ]] && choose_add "Checkout (diff2)" "cd"
[[ ! -z $checkout_diff_ours ]] && choose_add "Checkout (diff-ours)" "co"
[[ ! -z $checkout_diff3 ]] && choose_add "Checkout (diff3)" "cd3"
[[ ! -z $checkout_diff_name ]] && choose_add "Checkout (diff-name)" "cn"
[[ ! -z $remove ]] && choose_add "Remove (diff)" "dd"
[[ ! -z $merge_diff ]] && choose_add "Checkout (diff-merge)" "ma"

mod_safe=
mod_conflict=

git_flag_merge_conflict mod_safe mod_conflict "$mod_both"

[[ ! -z $mod_safe ]] && choose_add "Merge (safe)" "ms"
[[ ! -z $mod_conflict ]] && choose_add "Merge (conflict)" "mc"

################################################################################

choose_prompt="Choose: $choose_prompt
> "
choose_avail="${choose_avail%|}"

# do_with_option OPTION ACTION
function do_with_option {
  local option=$1
  local action=$2

  local option_p=${option:1}

  local preview_cmd=""
  local edit_cmd=""
  local git_cmd=""

  local prompt=""
  local list=""

  case $option in
    c?)
      # {1} = name to checkout, {2} = theirs id, {3} = theirs mod
      git_cmd="git_checkout_file"
      edit_cmd="emacsclient"

      case $option_p in
        's')
          preview_cmd="git show $theirs:{1}"
          prompt="Include (checkout, both)"
          list="$checkout_show";;
        'd')
          preview_cmd="git diff --color=always $base $theirs -- {1}"
          prompt="Include (checkout, base/theirs)"
          list="$checkout_diff" ;;
        'o')
          preview_cmd="git diff --color=always $ours $theirs -- {1}"
          prompt="Include (checkout, ours/theirs)"
          list="$checkout_diff_ours" ;;
        'd3')
          preview_cmd="git diff --color=always $base $ours $theirs -- {1}"
          prompt="Include (checkout, base/ours/theirs)"
          list="$checkout_diff3" ;;
        'n')
          preview_cmd="git diff --color=always {4} {5}"
          prompt="Include (checkout, rename base/theirs)"
          list="$checkout_diff_name" ;;
      esac
      ;;

    # NOTE: if the file exists in ours as a tree, it won't trigger this
    'dd')
      # {1} = name to remove
      git_cmd="git_remove_file"
      edit_cmd="emacsclient"
      preview_cmd="git diff --color=always $ours $theirs -- {2}"
      prompt="Exclude (remove, both)"
      list="$remove" ;;

    # r?)
    #   git_cmd="git_rename_file"
    #   edit_cmd="with_ediff"
    #   case $option_p in
    #     'n3')
    #       preview_cmd="git diff --color=always {1} {2} {3}"
    #       prompt="Include (checkout, rename base/theirs)"
    #       list="$checkout_diff3_name" ;;
    #     's')
    #       list="$rr_safe" ;;
    #     'u')
    #       list="$rr_conflict" ;;
    #     'es')
    #       git_cmd+="_existing"
    #       list="$rm_safe" ;;
    #     'eu')
    #       git_cmd+="_existing"
    #       list="$rm_conflict" ;;
    #   esac
    #   ;;

    m?)
      # {1}: theirs name, {2} theirs mod, {3}: ours name, {4}: ours id,
      # {5}: base id, {6}: theirs id
      git_cmd="git_merge_file"
      edit_cmd="ediff"

      case $option_p in
        'a')
          git_cmd+="_and_add"
          preview_cmd="git diff --color=always $ours $theirs -- {1}"
          prompt="Include (merge, ours/theirs)"
          list="$merge_diff" ;;
        's')
          preview_cmd="git diff --color=always $theirs $ours $base -- {1}"
          prompt="Include (merge, ours/base/theirs)"
          list="$mod_safe";;
        'c')
          git_cmd="false"
          preview_cmd="git diff --color=always $theirs $ours $base -- {1}"
          prompt="Include (merge, ours/base/theirs)"
          list="$mod_conflict" ;;
      esac
      ;;
  esac

  git_with_prompt \
    "$git_cmd" "$preview_cmd" "$edit_cmd" "$prompt: " "$action" \
    "$list"
}

function do_interactive {
  local quit_action=false

  while :; do
    read -p "$choose_prompt" choose

    case $choose in
      'q')
        echo "[ .. ] Bye"
        return 0 ;;
      'Q')
        echo "[ WW ] Forcing quit. Bye"
        exit 0 ;;
      '!')
        $SHELL; continue ;;
    esac

    if [[ ! "$choose" =~ $choose_avail ]]; then
      echo "[ !! ] Option not available"
      continue
    fi

    while :; do
      read -p "Do:
  Quit (q)
  act (aA)
  out (oO)
  edit (eE)
> " act

      case $act in
        'a'|'A'|'o'|'O'|'e'|'E') break ;;
        'q') quit_action=true; break ;;
        '') act="a"; break ;;
        *) echo "[ !! ] Option not available"; continue ;;
      esac
    done

    if $quit_action; then
      quit_action=false
      continue
    fi

    do_with_option "$choose" "$act"
  done
}

####

if $interactive; then
  do_interactive
fi

if [[ ! -z "$out" ]]; then
   echo "[ == ] Output:"
   echo "$out"
fi
