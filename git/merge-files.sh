#!/usr/bin/bash

gitidx=@GIT_MERGE_FILES_INDEX@

case $1 in
  '--help'|'-h')
    echo "Usage:       merge-files.sh [OPTIONS] THEIRS [BASE]"
    echo "Description: Operate in files changed in the merge/cherry with THEIRS,
  or future merge/cherry from OURS, with an optional merge base BASE"
    echo "Options:
  -i: run interactively
  -k: ignore renames
  -R: reverse THEIRS and OURS
  -o OURS: use OURS as OURS, instead of HEAD
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
    '-i') interactive=true;;
    '-o') p_val="ours";;

    '-ro') read_index="ours";;
    '-rt') read_index="theirs";;
    '-rb') read_index="base";;

    '-k') diff_opts="--no-renames";;

    '-R') reverse=true;;

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

null_id=$(git hash-object /dev/null) # use as base on A* types

case $read_index in
  "ours")
    if [[ -z $ours ]]; then
      ours=$($gitidx -r)
    else
      echo "[ WW ] Skip index read, because OURS is set"
    fi;;

  "theirs")
    if [[ "$theirs" == '.' ]]; then
      theirs=$($gitidx -r)
    else
      echo "[ WW ] Skip index read, because THEIRS is set"
    fi;;

  "base")
    if [[ -z $base ]]; then
      base=$($gitidx -r)
    else
      echo "[ WW ] Skip index read, because BASE is set"
    fi;;
esac

if [[ -z $ours ]]; then
  ours=HEAD
fi

if [[ -z $theirs ]]; then
  echo "[ !! ] Missing THEIRS. See \`--help'"
  exit 1
fi

ours=$(git rev-parse $ours)
theirs=$(git rev-parse $theirs)

if [[ -z $base ]]; then
  base=$(git merge-base $ours $theirs)
fi

base=$(git rev-parse $base)

if $reverse; then
  _ours=$ours

  ours=$theirs
  theirs=$_ours
fi

git_root=$(git rev-parse --show-toplevel)

################################################################################

function flatten {
  echo $@ | tr '\n' ' '
}

# cmd_with_stat FUNC ARGLIST LIST...
function cmd_with_stat {
  local func=$1
  local arglist=$2

  local ours_name=""
  local base_name=""
  local theirs_name=""
  local ours_id=""
  local base_id=""
  local theirs_id=""
  local ours_mod=""
  local base_mod=""
  local theirs_mod=""

  while read a1 a2 a3 a4 a5 a6 a7 a8 a9; do
    ours_name=$a1
    base_name=$a2
    theirs_name=$a3
    ours_id=$a4
    base_id=$a5
    theirs_id=$a6
    ours_mod=$a7
    base_mod=$a8
    theirs_mod=$a9
  done < <(echo "${@:3}")

  eval $func $arglist #</dev/tty
}


# ediff_func FUNCTION OURS_ID THEIRS_ID BASE_ID FILE
function ediff_func {
  local function=$1
  local ours_id=$2
  local theirs_id=$3
  local base_id=$4
  local file=$5

  emacsclient -e \
    "(progn (require 'mh-ediff-merge)
       (cd \"$git_root\")
       ($function
        \"$ours_id\" \"$theirs_id\" \"$base_id\" \"$file\"))"
}


# emacsclient_id THEIRS_ID FILE
function emacsclient_id {
  local theirs_id=$1
  local file=$2

  # create a buffer with name `file', and populate it with `theirs_id'
  emacsclient -e \
    "(progn (require 'mh-ediff-merge)
       (cd \"$git_root\")
       (let* ((buffer-name \"$git_root/$file\")
              (buffer (create-file-buffer buffer-name)))
         (with-current-buffer buffer
           (mh/git-show-cmd \"$theirs_id\" buffer)
           (setq buffer-file-name buffer-name)
           (switch-to-buffer buffer))))"
}

# edit_ediff3 LIST...
function edit_ediff3 {
  cmd_with_stat \
    "ediff_func mh/ediff-merge3" \
    '$ours_id $theirs_id $base_id $theirs_name' "$@"
}

# edit_ediff2 LIST...
function edit_ediff2 {
  cmd_with_stat \
    "ediff_func mh/ediff-merge2" \
    '$ours_id $theirs_id $base_id $theirs_name' "$@"
}

# edit_emacsclient_id LIST...
function edit_emacsclient_id {
  cmd_with_stat "emacsclient_id" '$theirs_id $theirs_name' "$@"
}

# with_editor EDITOR LIST...
function with_editor {
  local editor=$1
  local file=""

  while read line; do
    file=$(echo "${line/ */}")

    echo -n "[ ?? ] Edit this file: $file [Y/n] "
    read ans </dev/tty

    case $ans in
      ''|'y') eval $editor "$line";;
      *) echo "[ .. ] Ignoring";;
    esac
  done < <(echo "${@:2}")
}

# fzf_with_prompt PROMPT CMD
function fzf_with_prompt {
  local prompt=$1
  local cmd=$2

  fzfc \
      --prompt "$prompt"\
      --preview "$cmd"\
      --height=-40% -m
}

################################################################################

# git_diff_inc
function git_diff_inc {
  git -P diff --raw --cc --combined-all-paths $diff_opts \
    $theirs $base $ours -- | tr '\t' ' '
}

###

# _git_checkout_file THEIRS_MOD THEIRS_NAME OURS_NAME
function _git_checkout_file {
  local theirs_mod=$1
  local theirs_name=$2
  local ours_name=$3

  # if a directory (tree) exists with the same name, this would automatically
  # conflict, so we have to handle it
  if [[ -d $ours_name ]]; then
    echo -n "[ ?? ] A directory exists in \`ours' with the same name as
\`$ours_name'. What to do? [new name|(q)uit|(!)shell] "
    read ans </dev/tty

    case $ans in
      ''|'q') continue;;
      '!') $SHELL;;
      *)
        git update-index --verbose --replace --add --remove --cacheinfo "$theirs_mod,$oid,$ans"
        git restore $ans;;
    esac
  else
    git checkout $theirs -- $ours_name
  fi
}

# git_checkout_file LIST...
function git_checkout_file {
  cmd_with_stat _git_checkout_file '$theirs_mod $theirs_name $ours_name' "$@"
}

# _git_remove_file OURS_NAME PROMPT_FLAG
function _git_remove_file {
  local ours_name=$1
  local with_prompt=$2

  if $with_prompt; then
    local oty="$(git ls-tree -z --format='%(objecttype)' $ours $ours_name 2>/dev/null)"

    case $oty in
      'tree') echo "[ WW ] Skipping removing \`$ours_name', as it is a tree in \
OURS" ;;
      '') ;;
      *)
        git -P show "$ours:$ours_name" | more

        echo -n "[ ?? ] Checkout-like rename has resident source ($ours_name). \
Delete? [Y/n] "
        read ans </dev/tty

        if [[ -z "$ans" || "$ans" == 'y' ]]; then
          git rm -f $ours_name
        fi
    esac

  else
    git rm -f $ours_name
  fi
}

# git_remove_file LIST...
function git_remove_file {
  cmd_with_stat _git_remove_file '$ours_name "false"' "$@"
}

# _git_checkout_file_from_rename THEIRS_MOD THEIRS_NAME OURS_NAME BASE_NAME
function _git_checkout_file_from_rename {
  local theirs_mod=$1
  local theirs_name=$2
  local ours_name=$3

  # checkout `theirs_name'
  _git_checkout_file $theirs_mod $theirs_name $ours_name

  # ... then try to remove `base_name'
  _git_remove_file $base_name true
}

# git_checkout_file_from_rename LIST...
function git_checkout_file_from_rename {
  cmd_with_stat _git_checkout_file_from_rename\
    '$theirs_mod $theirs_name $ours_name $base_name' "$@"
}

# git_merge_file EDITCMD OURS_NAME BASE_NAME THEIRS_NAME OURS_ID BASE_ID \
#                THEIRS_ID OURS_MOD BASE_MOD THEIRS_MOD
function _git_merge_file {
  local editcmd=${1}
  local ours_name=${2}
  local base_name=${3}
  local theirs_name=${4}
  local ours_id=${5}
  local base_id=${6}
  local theirs_id=${7}
  local ours_mod=${8}
  local base_mod=${9}
  local theirs_mod=${10}

  local mod_conflict=false
  local bail=false

  # conflict if the mod of base-theirs or theirs-ours is different
  [[ ( "$base_mod" == "000000" || "$base_mod" != "$theirs_mod") && \
          "$theirs_mod" != "$ours_mod" ]] && mod_conflict=true

  if ! git merge-file -p -q --object-id $ours_id $base_id $theirs_id \
       >& /dev/null; then
    echo -n "[ !! ] File \`$theirs_name' conflicts. Resolve? [Y/n] "
    read ans </dev/tty

    if [[ ! -z $ans && $ans != 'y' ]]; then
      return 0
    fi

    eval "$editcmd $ours_name $base_name $theirs_name $ours_id $base_id \
$theirs_id $ours_mod $base_mod $theirs_mod"
    bail=true
  fi

  if $mod_conflict; then
    echo -n "[ ?? ] Mod conflicts: ours ($ours_mod), base ($base_mod), \
 theirs ($theirs_mod). What to do? [o|b|t|(q)uit|MOD] "
    read ans </dev/tty

    case $ans in
      'o') mod=$ours_mod ;;
      'b') mod=$base_mod ;;
      't') mod=$theirs_mod ;;

      'q') return 0 ;;

      *) mod=$ans ;;
    esac

    # TODO: not the best way to do this, but git is very idiosyncratic when it
    # comes to file permissions
    git add $theirs_name
    oid=$(git hash-object $theirs_name)
    git update-index --verbose --replace --add --remove --cacheinfo \
        "$mod,$oid,$theirs_name"
    git restore $theirs_name

    bail=true
  fi

  $bail && return 0

  # normal merge
  oid=$(git merge-file --object-id $ours_id $base_id $theirs_id)
  git update-index --verbose --replace --add --remove --cacheinfo \
      "$ours_mod,$oid,$theirs_name"
  git restore $theirs_name
}

# git_merge_file EDITCMD LIST...
function git_merge_file {
  local editcmd=$1

  cmd_with_stat \
    _git_merge_file \
    "$editcmd \$ours_name \$base_name \$theirs_name \$ours_id \$base_id \
\$theirs_id \$ours_mod \$base_mod \$theirs_mod" "${@:2}"
}

# _git_rename_file EDITCMD OURS_NAME BASE_NAME THEIRS_NAME OURS_ID BASE_ID \
#                  THEIRS_ID OURS_MOD BASE_MOD THEIRS_MOD
function _git_rename_file {
  local editcmd=${1}
  local ours_name=${2}
  local base_name=${3}
  local theirs_name=${4}
  local ours_id=${5}
  local base_id=${6}
  local theirs_id=${7}
  local ours_mod=${8}
  local base_mod=${9}
  local theirs_mod=${10}

  # merge into `theirs_name' ...
  _git_merge_file $editcmd $ours_name $base_name $theirs_name $ours_id \
    $base_id $theirs_id $ours_mod $base_mod $theirs_mod

  # ... then try to remove `base_name'
  _git_remove_file $base_name true
}

# git_rename_file EDITCMD LIST...
function git_rename_file {
  local editcmd=$1

  cmd_with_stat \
    _git_rename_file \
    "$editcmd \$ours_name \$base_name \$theirs_name \$ours_id \$base_id \
\$theirs_id \$ours_mod \$base_mod \$theirs_mod" "${@:2}"
}

# cmd_with_prompt CMD PROMPT PREVIEWCMD EDITCMD ACTION LIST...
function cmd_with_prompt {
  local cmd=$1
  local prompt=$2
  local fzfcmd=$3
  local editcmd=$4
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
    case $action in
      [Oo]) out+="$(echo "$choose" | awk '{printf("%s ", $1)}')" ;;
      *)
        echo "[ .. ] Running: $cmd"

        echo "$choose" | while read line; do
          eval "$cmd $line"
        done ;;
    esac
  fi
}

################################################################################

choose_prompt="
  Quit (q)
  Show (s)
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

echo "[ == ] With:
  OURS: $ours
  THEIRS: $theirs
  BASE: $base
"

echo "[ == ] git output (base->theirs/ours->theirs stat), (ours -> theirs file):"

git_out=""
NL=$'\n'

# ::100644 100644 100755 c5f24d6 c5f24d6 c5f24d6 MM Makefile Makefile Makefile
while read base_mod ours_mod theirs_mod \
           base_id ours_id theirs_id \
           base_ours_stat \
           base_name ours_name theirs_name; do
  base_mod="${base_mod#::}"

  if echo "$base_id" | grep -Eq '^0+$'; then
    base_id=$null_id
    base_mod=000000
  fi

  line="$ours_name $base_name $theirs_name $ours_id $base_id $theirs_id \
$ours_mod $base_mod $theirs_mod$NL"
  fline="  $base_ours_stat $ours_mod $ours_name:$ours_id -> \
$theirs_mod $theirs_name:$theirs_id$NL"

  git_out+="$fline"

  echo -n "$fline"

  case $base_ours_stat in
    # with checkout
    AA) checkout_show+="$line"; checkout_show_f+="$fline";;
    TT) checkout_diff_base_show+="$line"; checkout_diff_base_show_f+="$fline";;
    MA|TA) checkout_diff_base+="$line"; checkout_diff_base_f+="$fline";;
    MT) checkout_diff3+="$line"; checkout_diff3_f+="$fline";;
    AT) checkout_diff_ours+="$line"; checkout_diff_ours_f+="$fline";;
    # from rename
    RA) checkout_diff_name+="$line"; checkout_diff_name_f+="$fline";;
    RT) checkout_diff_name_show+="$line"; checkout_diff_name_show_f+="$fline";;

    # with remove
    DD) remove_diff_base_show+="$line"; remove_diff_base_show_f+="$fline";;

    # with merge (conflictable)
    # diff2
    AM) merge_diff_ours+="$line"; merge_diff_ours_f+="$fline";;
    # diff3
    MM|TM) merge_diff3+="$line"; merge_diff3_f+="$fline";;
    RM) merge_diff3_name+="$line"; merge_diff3_name_f+="$fline";;

    # with rename (merge conflictable)
    RR|MR|TR) rename_diff3+="$line"; rename_diff3_f+="$fline";;
    AR) rename_diff_ours+="$line"; rename_diff_ours_f+="$fline";;
  esac
done < <(git_diff_inc)

echo ""

###

[[ -z "$checkout_show" ]] || choose_add "Checkout (AA)" "csh"
[[ -z "$checkout_diff_base" ]] || choose_add "Checkout (MA/TA)" "cdb"
[[ -z "$checkout_diff_base_show" ]] || choose_add "Checkout (TT)" "cdbs"
[[ -z "$checkout_diff_ours" ]] || choose_add "Checkout (AT)" "cdo"
[[ -z "$checkout_diff3" ]] || choose_add "Checkout (MT)" "cd3"
[[ -z "$checkout_diff_name" ]] || choose_add "Checkout (RA)" "cdn"
[[ -z "$checkout_diff_name_show" ]] || choose_add "Checkout (RT)" "cdns"

[[ -z "$remove_diff_base_show" ]] || choose_add "Remove (DD)" "dsh"

[[ -z "$merge_diff_ours" ]] || choose_add "Merge (AM)" "mdo"
[[ -z "$merge_diff3" ]] || choose_add "Merge (MM/TM)" "md3"
[[ -z "$merge_diff3_name" ]] || choose_add "Merge (RM)" "md3n"

[[ -z "$rename_diff3" ]] || choose_add "Rename (RR/MR/TR)" "rd3"
[[ -z "$rename_diff_ours" ]] || choose_add "Rename (AR)" "rdo"

################################################################################

choose_prompt="Choose: $choose_prompt
> "
choose_avail="${choose_avail%|}"

# git_out_show_typ TYPE
function git_out_show_typ {
  local type=$1

  case $type in
    #### WITH CHECKOUT:
    'csh') echo "$checkout_show_f";;
    'cdbs') echo "$checkout_diff_base_show_f";;
    'cdb') echo "$checkout_diff_base_f";;
    'cdo') echo "$checkout_diff_ours_f";;
    'cd3') echo "$checkout_diff3_f";;
    # also try to remove the origin
    'cdn') echo "$checkout_diff_name_f";;
    'cdns') echo "$checkout_diff_name_show_f";;

    #### WITH REMOVE:
    # NOTE: if the file exists in ours as a tree, it won't trigger this
    'dsh') echo "$remove_diff_base_show_f";;

    #### WITH MERGE:
    'mdo') echo "$merge_diff_ours_f";;
    'md3') echo "$merge_diff3_f";;
    'md3n') echo "$merge_diff3_name_f";;

    #### WITH RENAME-MERGE
    'rd3') echo "$rename_diff3_f";;
    'rdo') echo "$rename_diff_ours_f";;
  esac
}

# do_with_option OPTION ACTION
function do_with_option {
  local option=$1
  local action=$2

  local preview_cmd=""
  local edit_cmd=""
  local git_cmd=""

  local prompt=""
  local list=""

  # {1}: ours_name, {2}: base_name, {3}: theirs_name,
  # {4}: ours_id,   {5}: base_id,   {6}: theirs_id
  # {7}: ours_mod,  {8}: base_mod,  {9}: theirs_mod,
  case $option in
    #### WITH CHECKOUT:
    'csh')
      git_cmd="git_checkout_file"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git show $theirs:{3}"
      prompt="Include (checkout, show theirs)"
      list="$checkout_show";;
    'cdbs')
      git_cmd="git_checkout_file"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always $base $ours -- {1};\
echo '>>>>>>> THEIRS'; git show $theirs:{1}"
      prompt="Include (checkout, show theirs)"
      list="$checkout_diff_base_show";;
    'cdb')
      git_cmd="git_checkout_file"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always $base $theirs -- {1}"
      prompt="Include (checkout, diff base/theirs)"
      list="$checkout_diff_base";;
    'cdo')
      git_cmd="git_checkout_file"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always $ours $theirs -- {1}"
      prompt="Include (checkout, diff ours/theirs)"
      list="$checkout_diff_ours";;
    'cd3')
      git_cmd="git_checkout_file"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always $theirs $base $ours -- {1}"
      prompt="Include (checkout, diff base/theirs,ours/theirs)"
      list="$checkout_diff3";;
    # also try to remove the origin
    'cdn')
      git_cmd="git_checkout_file_from_rename"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always {5} {6}"
      prompt="Include (checkout, rename base/theirs)"
      list="$checkout_diff_name";;
    'cdns')
      git_cmd="git_checkout_file_from_rename"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always {5} {6}; echo '>>>>>>> OURS'; \
git show $ours:{1}"
      prompt="Include (checkout, rename base/theirs, type ours)"
      list="$checkout_diff_name_show";;

    #### WITH REMOVE:
    # NOTE: if the file exists in ours as a tree, it won't trigger this
    'dsh')
      git_cmd="git_remove_file"
      edit_cmd="edit_emacsclient_id"
      preview_cmd="git diff --color=always $base $ours -- {1}; \
echo '>>>>>>> OURS'; git show $ours:{1}"
      prompt="Exclude (remove, diff base/ours)"
      list="$remove_diff_base_show";;

    #### WITH MERGE:
    'mdo')
      edit_cmd="edit_ediff2"
      git_cmd="git_merge_file $edit_cmd"
      preview_cmd="git diff --color=always $ours $theirs -- {1}"
      prompt="Include (merge, ours/theirs)"
      list="$merge_diff_ours";;
    'md3')
      edit_cmd="edit_ediff3"
      git_cmd="git_merge_file $edit_cmd"
      preview_cmd="git diff --color=always $theirs $ours $base -- {1}"
      prompt="Include (merge, diff ours/theirs,base/theirs)"
      list="$merge_diff3";;
    'md3n')
      edit_cmd="edit_ediff3"
      git_cmd="git_merge_file $edit_cmd"
      preview_cmd="git diff --color=always {5} {6}; \
echo '>>>>>>> OURS/THEIRS'; git diff --color=always {4} {6}"
      prompt="Include (merge, diff base/theirs ours/theirs)"
      list="$merge_diff3_name";;

    #### WITH RENAME-MERGE
    'rd3')
      edit_cmd="edit_ediff3"
      git_cmd="git_rename_file $edit_cmd"
      preview_cmd="git diff --color=always {5} {6}; \
echo '>>>>>>> OURS/THEIRS'; git diff --color=always {4} {6}"
      prompt="Include (rename, diff base/theirs ours/theirs)"
      list="$rename_diff3";;
    'rdo')
      edit_cmd="edit_ediff2"
      git_cmd="git_rename_file $edit_cmd"
      preview_cmd="git diff --color=always {4} {6}"
      prompt="Include (rename, diff ours/theirs)"
      list="$rename_diff_ours";;
  esac

  cmd_with_prompt \
    "$git_cmd" "$prompt: " "$preview_cmd" "$edit_cmd" "$action" \
    "$list"
}

function do_interactive {
  local quit_action=false

  while :; do
    read -p "$choose_prompt" choose

    case $choose in
      'q') echo "[ .. ] Bye"; return 0;;
      's') echo "$git_out"; continue ;;
      '!')
        $SHELL; continue;;
    esac

    if [[ ! "$choose" =~ $choose_avail ]]; then
      echo "[ !! ] Option not available"
      continue
    fi

    # prompt action
    while :; do
      read -p "Do:
  Quit (q)
  Show (s)
  Act (aA)
  Out (oO)
  Edit (eE)
> " act

      case $act in
        # passthrough to `do_with_option'
        [Aa]|[Oo]|[eE]) break;;

        'q') quit_action=true; break;;
        's') git_out_show_typ "$choose"; continue ;;
        '') act="a"; break;;
        *) echo "[ !! ] Option not available"; continue;;
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
