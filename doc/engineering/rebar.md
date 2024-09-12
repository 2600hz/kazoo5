# Kazoo Rebar3 built tool support (Experimental)

[Rebar3](https://rebar3.org) official build tool for Erlang/OTP. When development of Kazoo was started there was no Rebar3 so that is why [GNU `make`](https://www.gnu.org/software/make/) was chosen for its build system.

Since Rebar3 is now mature enough and adopted by almost all Erlang projects, by supporting in Kazoo can now benefit of supporting Rebar3 and have better integration and interoperability with other tools such as code editors, other Erlang libraries and Erlang tools (such as [ErlangLS](https://github.com/erlang-ls/erlang_ls)) and way much faster build time.

Rebar3 in Kazoo is still experimental and won't replace the existing make build system.
Current Make build system is still the official build system supported by Kazoo.

The umbrella Rebar configuration in provided by kazoo5 repository and each application (in `core/` and `applications/`) can have their own `rebar.config` with any customizations needed by that particular application.

> **NOTE** All Rebar commands must be run from root of Kazoo source code.

This document present the current workflow of using Rebar3 and track what is working and
what is not.

Users of macOS and Windows can benefit of this since building and running a dev Kazoo
release is now depends less on Makefiles.



## Prerequisites

You must have the usual Kazoo dev environment installed, mainly:

1. A Kazoo supported Erlang/OTP version
2. [Rebar3](https://rebar3.org)
3. Git (at least Git v2)
4. Essential build tools (`build-essential` in Debian) which may include GCC/G++, make,
   automake, autoconf, zip/unzip and etc...
5. Other Kazoo required stack if you want to a dev release (CouchDB, RabbitMQ at least).

Consult [Installation](../installation.md) and [Installing on macOS](./installing-on-mac.md) for more info.

## Fetch Core and Kazoo Apps

You still need to manually fetch Kazoo Core and Kazoo Applications. Go ahead and copy
`make/more_apps.mk.default` to `make/mores_apps.mk` if you have't already. Add any other extra
Kazoo application repositories you want to fetch and run the command in the root of
Kazoo source code directory:

```shell
# edit (or copy make/more_apps.mk.default to make/mores_apps.mk) and extra kazoo apps repos
# if needed

# and now fetch repos by:
make fetch-core fetch-apps
```

## Get yourself familiar with `rebar3`

> **NOTE** All Rebar commands must be run from root of Kazoo source code.

Running `rebar3` without any argument will print its help. If you need to need more about some
specific Rebar sub-command or it options, you can use:

```
rebar3 help {sub_commnad}
```

See Rebar3 [documentation](https://rebar3.org/docs/commands/) for more info.

## Compile (whole project, including fetch and compile deps)

> **NOTE** Please keep `make/deps.mk` and `rebar.config` deps in sync

Almost all sub-commands of `rebar3` are depend on `compile` and they will trigger it. But
if you want explicitly run it, simply type and run:

```
rebar3 compile
```

This will always fetch and compiles any missing dependency.

By default rebar is using `_build` directory. You will find all Beam files in `default`
target at `_build/default/lib` path.

Recent version Rebar3 compile everything in parallel, which makes compile deps + core +
kapps to something under ~3mins from cold start!

### Side note

If you already compile the project using `make`, I recommend to `make clean clean-deps`
before compiling.

Rebar3 usually copies any beam files from ebin directory to its build directory.

In some rare cases (removing old source file, apps and etc) it is better to start fresh,
remove `_build` and compile. It is fast enough.

### Clean

This is not so much needed but if you need:

```
rebar3 clean
```

See documents for more info.

In rare case it is better to remove `_build` directory and start over.

## Erlang Releases

### `kazoo_dev` Release

For most dev time cases, a default relx release is provided with name `kazoo_dev`.
If you need more release targets, see section about local rebar3 config.

For building the `kazoo_dev` release:

```
rebar3 release -n kazoo_dev
```

Please be advise that we use special `vm.args` and `sys.config` for rebar releases (check `rel/rebar.dev.*` files).

#### Kazoo `config.ini`

To run Kazoo you may need create a `config.init`. A bare minimum config file is provided in `rel/rebar.dev.kazoo-config.ini`.
Copy the file to `/etc/kazoo/core/config.init`:

```shell
sudo mkdir -p /etc/kazoo/core
sudo cp -n rel/rebar.dev.kazoo-config.ini /etc/kazoo/core/config.ini
```

#### Running `kazoo_dev` release

Simply use this to run a kazoo dev release (`reloader` is attached to track recompile beam files):

```
_build/default/rel/kazoo_dev/bin/official_kazoo console
```

You will get an Erlang shell. Consult that `official_kazoo` script for more sub-commands.

#### Log files

Log files are in `_build/default/rel/kazoo_dev/log/`. `ra` directory is at `_build/default/rel/kazoo_dev/ra`.

#### Changing Erlang node name

Before running the release `official_kazoo` script, export your node name in `KAZOO_NODE` variable:

```shell
export KAZOO_NODE=ecallmgr

# or combine it with running release
KAZOO_NODE=ecallmgr _build/default/rel/kazoo_dev/bin/kazoo_dev console
```

By default `kazoo_apps` is used as node name.

#### Changing Erlang Cookie

Before running the release `official_kazoo` script, define your cookie for the node name in your Kazoo config file
in `/etc/kazoo/core/config.ini`. Default cookie is `change_me`.

```
; example cookie configuration for kazoo_apps node
[kazoo_apps]
cookie = mycookie_is_awesome
```

## Dialyzer

As easy as:

```
rebar3 dialyze
```

### Caveat

- There is no way to ignore false-positive warnings as we already do in `scripts/chech-dialyzer.escript`
- There is no way to run dialyzer for only changed files, by at least it is not too slow!
- Currently we complete ignore `lager` module mostly to silent warnings regarding return
  type not matched.

## Xref

```
rebar3 xref
```

There is some ignore configurations in `rebar.config` to silent deps.

### Caveat

- There is no way to run this for only changed files, by at least it is not too slow!

## Run Tests (Eunit and PropEr)

I suggest to add `--cover` option to you generate test coverage report. This will run both
EUnit and PropEr tests:

```
rebar3 eunit --cover
```

then to create and print coverage:

```
rebar3 cover -v
```

## Local custom Rebar3 configuration

If you need to customize rebar3 configuration to your needs (add extra release targets, deps and etc...), you may
create `rebar.local.config` in the root of Kazoo source directory. Our `rebar.config.script` will consult this file if exists.
These variables are bounded and can be use in your config file:

- `CONFIG`: Updated Rebar3 config variable, you MUST return this after updating it to your liking.
- `PROJECT_APPS`: A variable that holds all Kazoo and Core applications, useful to use as a list of apps when adding a new release target.
- `BASE_APPS`: Our list of recommaned Erlang system apps.

Your file need to return an updated rebar3 config.

Example `rebar.local.config` to add new release targets, one simulating a procution, and another one only generating a release for `ecallmgr` app):

```erlang
{relx, Releases} = case lists:keyfind(relx, 1, CONFIG) of
                       'false' ->
                           {relx, []};
                       Relx -> Relx
                   end,


MyReleases =
        [{release
         %% release name and version
         ,{kazoo_next, "5.5"}
         %% add apps to included in this release, required. You can use provided Kazoo PROJECT_APPS and BASE_APPS if you like.
         ,BASE_APPS ++ PROJECT_APPS
         %% release configuration
         ,[{mode, prod}
          ,{include_src, false}
          ,{include_erts, false}
          ,{dev_mode, false}
          ,{generate_start_script, false}
          ,{extended_start_script, false}
          ,{sys_config, "rel/rebar.dev.sys.config.src"}
          ,{vm_args, "rel/rebar.dev.vm.args.src"}
          ,{check_for_undefined_functions, false}
          ,{overlay, [{copy, "core/sup/priv/sup", "{{output_dir}}/bin/"}
                     ,{copy, "rel/nodetool", "{{output_dir}}/bin/"}
                     ,{template, "rel/kazoo", "{{output_dir}}/bin/kazoo"}
                     ,{chmod, 8#00755, "{{output_dir}}/bin/kazoo"}
                     ,{copy, "rel/rebar.dev.kazoo-config.ini", "etc/kazoo.ini"}
                     ]
           }
          ]
         }
        ,{release
         %% release name and version
         ,{ecallmgr, {git, short}}
         %% add apps to included in this release, required. You can use provided Kazoo PROJECT_APPS and BASE_APPS if you like.
         ,[ecallmgr]
         %% release configuration
         ,[{mode, dev}
          ,{include_src, false}
          ,{include_erts, false}
          ,{dev_mode, true}
          ,{generate_start_script, false}
          ,{extended_start_script, false}
          ,{sys_config, "rel/rebar.dev.sys.config.src"}
          ,{vm_args, "rel/rebar.dev.vm.args.src"}
          ,{check_for_undefined_functions, false}
          ,{overlay, [{copy, "core/sup/priv/sup", "{{output_dir}}/bin/"}
                     ,{copy, "rel/nodetool", "{{output_dir}}/bin/"}
                     ,{template, "rel/kazoo", "{{output_dir}}/bin/kazoo"}
                     ,{chmod, 8#00755, "{{output_dir}}/bin/kazoo"}
                     ,{copy, "rel/rebar.dev.kazoo-config.ini", "etc/kazoo.ini"}
                     ]
           }
          ]
         }
        ],

lists:keystore(relx, 1, CONFIG, {relx, Releases ++ MyReleases}).
```
