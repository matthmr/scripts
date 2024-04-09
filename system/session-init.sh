#!/usr/bin/bash

# By session:
#  $1: session type (X, tty, ...)
#  $2: wm

TYPE=$1
SESSION=$2

function session_msg {
  local msg=$1

  echo "[ $(date +%s) ] $msg" >> /tmp/session-msg
}

#### MPD

if [[ ! -f /tmp/mpd-pid ]]; then
  mpd 1>/dev/null 2>/dev/null &
fi

#### DOCS (attach the terminal here)

if [[ ! -f /tmp/emacs/docs-lock ]]; then
  mkdir -m 700 -p /tmp/emacs

  touch /tmp/emacs/docs-lock
  touch /tmp/emacs/daemon.log

  # NOTE: I'm repeating because Emacs itself can be the window manager, in which
  # case you should handle `SESSION' in TYPE=x to *not* start emacs and docs
  case $TYPE in
    'x')
      SESSION=$SESSION emacss start >> /tmp/emacs/daemon.log 2>&1
      docs -s journal >> /tmp/emacs/daemon.log 2>&1
      (tmuxa -x 'docs' &) ;;
    'tty')
      case $SESSION in
        'tmux')
          SESSION=$SESSION emacss start >> /tmp/emacs/daemon.log 2>&1
          docs -s journal >> /tmp/emacs/daemon.log 2>&1
          tmuxa 'docs' ;;
      esac
  esac
fi

#### SCHEDL

if [[ ! -f /tmp/schedl/session-lock ]]; then
  mkdir -p /tmp/schedl

  touch /tmp/schedl/session-lock
  touch /tmp/schedl/schedl.log

  @SESSION_INIT_SCHEDL@

  jobs=$(find /tmp/schedl -type f \
              -not -name '*.sh' -not -name '*.log' -not -name 'session-lock' \
           2>/dev/null)
  sh_jobs=$(find /tmp/schedl -type f \
                 -name '*.sh' 2>/dev/null)

  # TODO: should be a proper job
  if [[ -f /tmp/schedl/update-system ]]; then
    session_msg "Note: There is a system session pending"
  fi

  if [[ ! -z $jobs ]]; then
    for job in $(echo $jobs | tr '\n' ' '); do
      session_msg "Schedl Job ($job): $(cat $job)"
    done
  fi

  if [[ ! -z $sh_jobs ]]; then
    session_msg "Note: There are Schedl script jobs pending"
    tmux new-session -d \
         -s 'schedl' "LOGINCMD=@SESSION_INIT_LOGINCMD@ zsh"
  fi
fi
