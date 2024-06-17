# Login stack

This directory has, among other scripts, the login stack of a system using these
scripts.

## `session`

We execute the `session` script in a user login script like `~/.profile`. Inside
the `session` script we may choose a *session* to login with. A session is any
program we execute right after login, overriding the login shell. In the
`session` script, you may change the values of `@SESSION_SESSIONS@` and populate
the bash array with programs you'd like to login to.

Once you choose a session to login with, it'll be saved in the global `SESSION`,
which should be handled by the login program.

You may execute a command in the shell by setting the `LOGINCMD` variable.

## X

We have built-in scripts for X sessions (DEs, WMs, ...). We use the `sx` script,
which I have a fork of that works with these scripts. The `sx` config file (in
the `config` repository) runs `xdaemon` before executing the login command.

### `xdaemon`

`xdaemon` starts "daemon" programs within X.

## TTY

As said above, you may set the `LOGINCMD` variable to execute commands before
launching the proper session.

## Messaging

These scripts integrate with another program of mine called `schedl`, which
allows me propmt the scheduled execution of commands or display scheduled
messages. The script reponsible for these is `session-msg`.

### `session-msg`

If running in X, it'll try to spawn a terminal emulator with tmux. If on a tty,
it'll try to spawn tmux.

This script **should** only run once. It'll save its messages to
`/tmp/session-msg.txt`.

The messaging script will call `session-init`.

### `session-init`

`session-init` is a script that inits common programs regardless of session type
(X, tty, ...)

### `schedl`

Optionally, you may integrate your login stack with `schedl`. By calling the
`job/schedl.sh` scripts and processing the results.

# About

This is just an overview of the stack. I suggest you read the scripts mentioned
to get a better idea.
