# Getting used to multi-repo

INTRODUCTION

## {% BRAND_NAME %} new source directory structure

Write something useful here

## Compiling in multi-repo

Explain what is going on with each app Makefile and dep.mk, etc....

## Working with `git` in multi-repo

As you work with multi-repo, especially when your code changes involves many apps or even the core, you start noticing some repetitive tasks like commit and push and updating the pull requests.

For making these kind of task more tolerable, there is small and handy `kgit` shell script which wraps around Git command. You simply give this script the directory name of an app (or multiple apps) and the git command you want to run against them and it loop over the folders and run the command. This script can also used together with `gh` [the official GitHub CLI](https://cli.github.com) or `hub` [an unofficial GitHub CLI](https://github.com/github/hub) (which is more mature and powerful and it also wraps `git`) commands.

The script tries to not get in your way and offers running `git` and other commands like normal command.

```
    __ _______         _ __
   / //_/__  /  ____ _(_) /_
  / ,<    / /  / __ `/ / __/
 / /| |  / /__/ /_/ / / /_
/_/ |_| /____/\__, /_/\__/ ☢
Welcome to   /____/ the FUTURE

A simple wrapper around git and pull request commands
to provide an easy way to develop on Kazoo multi-repo structure

Usage:

        kgit.sh [OPTIONS]+ <ACTION> [ACTION_ARGS]+

    Where ACTION can be one of these commands to run in specified
    Kazoo source folders:

        git        Runs git command
        gh         Runs gh command (https://cli.github.com)
        hub        Runs hub command (https://github.com/github/hub)
        cmd        Run arbitrary command

Example:

    kgit.sh -kapps crossbar,teletype git status --branch --short

Options:

# Filter directories by their type
    -kapps app_name[,app_name...]        add a comma separated list of Kazoo apps to working directories list
    -exclude-apps app_name[,app_name...] exclude a comma separated list of Kazoo apps from working directories list
                                             This takes precedence over -kapps, -a and -A.
    -kcore                               add "core" directory to working directories list
    -kroot                               add kazoo source root directory to working directories list
    -a, --all-apps                       add all Kazoo apps to working directories list
    -A, -All                             add "core", all kazoo apps and kazoo source root directory to
                                             list of working directories. This option is default

# Skip directories that have changes

 Skip option will override their "only run on directory" option below if both are specified

    -not-changed-uncommitted             skip directories that have not committed changes (any staged or unstaged changes)
    -not-changed-unpushed                skip directories that have not any diff between its branch HEAD and its origin (unpushed commits)
    -not-changed-base                    skip directories that have not any diff with their base branch
    -not-changed-latest                  skip directories that have not any diff with their branch latest tag
                                             (if no tag, uses base branch)
    -not-changed                         this skips any directories that have any changes or diff
                                             either committed or unpushed commits or diff with base branch

# Only run on directories that have changes
    -only-changed-uncommitted            only run on directories that uncommitted changes (staged or unstaged)
    -only-changed-unpushed               only run on directories that have diff between its branch HEAD and its origin (unpushed commits)
    -only-changed-base                   only run on directories that have diff with their base branch
    -only-changed-latest                 only run on directories that have diff with their latest tag
                                             (if no tag, uses base branch)
    -only-changed                        only run on directories that have any changes or diff
                                             either committed or unpushed commits and/or diff with base branch

# Useful utility commands
    -get-root                            print path to Kazoo source directory and exit
    -show-changed                        loop over working directories and prints the name of files which are
                                             different than "$BASE_BRANCH". "master" is the default BASE_BRANCH
                                         this does not run git/hub/gh commands

# Other Options
    -exit-on-error                       exit if command returns exit other than 0 in a directory
    -q                                   be quiet, but still print error messages
    -qq                                  be more quiet, also do not print errors
    -h, -help                                shows help
```


It is recommended to sym-link this script to `kgit` and put it in your path. `kgit-completion.bash` provides bash completion for `kgit`. You can source this directly in your shell or add to your `~/.bashrc`.

### Some useful examples for working with `kgit`

```shell
# pull all apps
$ kgit -a git pull

# run git status in all directories
$ kgit git status

# too noisy output, huh? make it short:
$ kgit git status --branch -s

# some git subcommands use pager, you can trun this off by "--no-pager"
# see latest commit message for core, crossbar, stepswitch and teletype
$ kgit -kcore -kapps crossbar,stepswitch,teletype git --no-pager log -1

# make it less noisy
$ kgit -q -kcore -kapps crossbar,stepswitch,teletype git --no-pager log -1 --format

# commit all changes just for core and root directory
# this will opens up your editor for each directory for commit message
# you can use "-m" to add message. you can even add multiple "-m" which converts
# each one to a paragraph
$ kgit -kcore -kroot git commit -a

# commit all changes in all directories with "kazoo is great" as commit title
# and "my explaination" as commit body
# kgit git commit -a -m "kazoo is great" -m "my explaination"

# commit all changes in all directories with a message authored in a external file
# please refer to git manual for format of the file
$ vim /tmp/commit-message.txt
$ kgit git commit -a -F /tmp/commit-message.txt


# Run arbitary commands
$ kgit cmd ls
$ kgit cmd bash -c 'basename $(pwd)'
$ kgit cmd cp ~/lol.json priv/
```

### Examples for working with pull-requests

!!! note
    These are just example to show you the new work flow. Please adjust it to your work flow.

!!! note
    For simplicity we are applying the command to all directories. Obviously you can adjust to work with directory that you need, using `-kapps`, `--all-apps`, `-kcore` or `-kroot` accordingly.

```shell
# forking all using hub
# Note: hub after forking is adding a git remote for it to each dir
# please refer to hub documentation for more info
$ make fetch-apps fetch-core
$ kgit hub fork

# create a new branch in all dirs
$ kgit git checkout -b my_new_branch

# start hacking!, add/remove or update some files
#

# after coding, commit your changes to the your branch
$ kgit git commit -a -m "make kazoo even better"

# push your codes to your forked repos
$ kgit git push --set-upstream origin my_new_branch

# finally create pull requests for all changed repos
$ vim /tmp/pr-message.txt
$ kgit hub pull-request -F /tmp/pr-message.txt

# after a few mintues check PRs for their CI checks
$ kgit hub ci-status
```

Please find out usage examples for `gh` and `hub` here:

* [`gh` Examples in use](https://cli.github.com/manual/examples)
* [`hub` Usage examples](https://hub.github.com)

### Filter the directories that kgit would run by its type

If you need to run the command only for kazoo-applications, core or root:

```
# to run only on all applications/*
kgit -a git status --branch -s

# to run only on core
kgit -kcore git status --branch -s

# to run only on kazoo root
kgit -kroot git status --branch -s

# to only run in specific applications
kgit -kapps crossbar,ast -kapps properly git status --branch -s

# to exclude (not run) on specific applications
kgit -exclude-apps crossbar,ast git status --branch -s
```

### Filter the directories that kgit would run based on its git status

Do not mix `only-changed*` and `not-changed*` options!

#### If you need to run the commands on certain git status conditions of the directory

```
# run the command only if current branch has uncommitted changes
kgit -only-changed-uncommitted git commit -a -m 'awesome work'

# run the command only if HEAD of current branch has differences with its `origin` base branch (you may want to
pull down to update your local origin)
kgit -only-changed-base git commit -a -m 'awesome work'

# run the command only if HEAD of current branch has differences with its `origin` (you may want to
pull down to update your local origin)
# this is different from origin base branch as it only compares with the current branch
# like if you on PR-BRANCH-1 and want to run command only if your local HEAD is different
# from `origin/PR-BRANCH-1.
# This is useful for situation you did not yet pushed your commit to Github yet.
kgit -only-changed-unpushed git commit -a -m 'awesome work'

# run the command only if HEAD of current branch has differences with the latest tag of the branch (you may want to
pull down to update your local origin)
#
# CAUTION: this may be result incorrect behaviour, especially when the `master` branch has
# tag in it. User discretion is applied!
kgit -only-changed-latest git commit -a -m 'awesome work'
```

#### If you DO NOT want to run the commands on certain git status conditions of the directory

Same as above, but negates the logic to skip the directory if the directory status is not
clean.

```
-not-changed-uncommitted             skip directories that have not committed changes (any staged or unstaged changes)
-not-changed-unpushed                skip directories that have not any diff between its branch HEAD and its origin (unpushed commits)
-not-changed-base                    skip directories that have not any diff with their base branch
-not-changed-latest                  skip directories that have not any diff with their branch latest tag
                                         (if no tag, uses base branch)
-not-changed                         this skips any directories that have any changes or diff
                                         either committed or unpushed commits or diff with base branch
```
