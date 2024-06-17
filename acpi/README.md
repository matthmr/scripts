# ACPI stack

This directory has the ACPI stack of a system using these scripts.

# `doshutdown/doreboot`

*Shutdown* and *reboot* are considered in the same class of action. If you want
to shutdown or reboot the system, you'll call `doshutdown` or `doreboot`.

Depending whether you've run them with the *force* option, you'll be prompted to
confirm (the scripts for which are `shutdown-confirm` and `reboot-confirm`), or
you'll run *lock* scripts (the scripts for which are `shutdown-lock` and
`reboot-lock`). The *lock* scripts will eventually run the *confirm* scripts.

## `shutdown-lock/reboot-lock`

The *lock* scripts will prompt you to run some commands before shutting down.

## `shutdown-confirm/reboot-confirm`

The *confirm* scripts contain the final ACPI command that'll be sent to the
kernel.

# `dosuspend/dohibernate`

*Suspend* and *hibernate* are considered in the same class of action. If you
want to suspend or hibernate the system, you'll call `dosuspend` or
`dohibernate`.

Either script will call `suspend-confirm` or `hibernate-confirm`.

## `suspend-confirm/hibernate-confirm`

The *confirm* scripts will simply confirm if you want to proceed with the ACPI
action. There are no hooks in these scripts.

The ultimate ACPI command is contained in `suspend.sh` and `hibernate.sh` using
the `sysfs` interface provided by the kernel. More specifically
`/sys/power/state`.

# Flags

Most scripts in here have X (-x) and tmux (-t) flags for attaching to a tmux
session, creating a terminal emulator window within X, and so on.

# About

This is just an overview of the stack. I suggest you read the scripts mentioned
to get a better idea.
