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

You may execute a command in the shell by setting the `INIT` variable.

## X

We have built-in scripts for X sessions (DEs, WMs, ...). We use the `sx` script,
which I have a fork of that works with these scripts. The `sx` config file (in
the `config` repository) runs `xdaemon` before executing the login command.

### `xdaemon`

`xdaemon` starts "daemon" programs within X.

## TTY

As said above, you may set the `INIT` variable to execute commands before
launching the proper session.

## Init

You may want your session to executing some commands regardless of
(or depending on) the type of the session. This is done through the
`system/session-init.sh` script, which takes a session *type*, and the session
*name*.

The init script can also *attach*, which means bringing the commands into
attention by calling some sort of terminal to display the outputs/prompt for
execution/etc.

# About

This is just an overview of the stack. I suggest you read the scripts mentioned
to get a better idea.
