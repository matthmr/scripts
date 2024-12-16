# Syntax

This is the syntax for files processed by `git.sh`

```
  LOCAL_REPO_ORIGIN [LOCAL_REPO_BRANCH] [REMOTE_REPO_ORIGIN] [REMOTE_REPO_BRANCH]
```

Every entry will fetch from `REMOTE_REPO_ORIGIN` (or origin if empty), given
branch `REMOTE_REPO_BRANCH` (or master if empty), `to LOCAL_REPO_ORIGIN` at
branch `LOCAL_REPO_BRANCH` (or master if empty)

## Set default

If `LOCAL_REPO_BRANCH` has a `*` in front, then it will assume its value as
the default value of `REMOTE_REPO_BRANCH`, if it's left empty. For example:
```
  /path/to/git/repo *main -> /path/to/git/repo main origin main
```

## Use default

You can skip a field by setting it to `.`. Its value will then be the one of the
defaults. For example:
```
  /path/to/git/repo . origin main -> /path/to/git/repo master origin main
```

## Fetch into

If `LOCAL_REPO_BRANCH` has a `:` in it, separating right hand-side from left
hand-side, it's equivalent to:
```
  /path/to/git/repo main:master -> /path/to/git/repo master origin main
```
Either side left empty means `master`

## Messaging

The script can trigger `update`-type messages based on a set of criteria set in
the file.

### branch-fork

The `bf` criterion triggers when the defined branch (`FORK_BRANCH`) is not
parented by `LOCAL_REPO_BRANCH`, it has the following syntax:
```
  bf:FORK_BRANCH:/path/to/git/repo ...
```

`FORK_BRANCH` being left empty means `master`.

### tag-fork, tag

The `tf` and `tag` criteria trigger whenever a new tag is fetched. The only
difference is in user-side, because `tf` will need to be merged. They have the
following syntax:
```
  tf:/path/to/git/repo ...
  tag:/path/to/git/repo ...
```

### remote-branch-fork, remote-tag-fork

The `rbf` and `rtf` criteria are similar to their non-remote counterparts, the
only difference being in how the user should handle them, i.e. the fork has
another *remote* counterpart.
