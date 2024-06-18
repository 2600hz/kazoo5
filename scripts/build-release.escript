#!/usr/bin/env escript
%%! +A0 -sname kazoo_relx
%% -*- coding: utf-8 -*-

-mode('compile').

-export([main/1]).

%% API

main([]) ->
    print_help(1);
main(CommandLineArgs) ->
    {'ok', Options, Args} = parse_args(CommandLineArgs),

    io:format("options: ~p~nargs: ~p~n", [Options, Args]),

    RelxConfig = get_relx_config(Options),

    StartTime = kz_time:start_time(),
    relx_release(Options, RelxConfig),
    io:format("built release in ~p ms~n", [kz_time:elapsed_ms(StartTime)]).

relx_release(Options, RelxConfig) ->
    relx_release(Options, RelxConfig, lists:keyfind('release', 1, RelxConfig)).

relx_release(Options, RelxConfig, {'release', {Name, {'cmd', Cmd}}, _}) ->
    Vsn = os:cmd(Cmd),
    build_release(Options, RelxConfig, Name, Vsn);
relx_release(Options, RelxConfig, {'release', {Name, 'semver'}, _}) ->
    build_release(Options, RelxConfig, Name, "");
relx_release(Options, RelxConfig, {'release', {Name, {'semver', _}}, _}) ->
    build_release(Options, RelxConfig, Name, "");
relx_release(Options, RelxConfig, {'release', {Name, {'git', 'short'}}, _}) ->
    Vsn = string:trim(os:cmd("git rev-parse --short HEAD"), 'both', "\n"),
    build_release(Options, RelxConfig, Name, Vsn);
relx_release(Options, RelxConfig, {'release', {Name, {'git', 'long'}}, _}) ->
    Vsn = string:trim(os:cmd("git rev-parse HEAD"), 'both', "\n"),
    build_release(Options, RelxConfig, Name, Vsn);
relx_release(Options, RelxConfig, {'release', {Name, Vsn}, _}) ->
    build_release(Options, RelxConfig, Name, Vsn).

build_release(Options, RelxConfig, Name, Vsn) ->
    {'ok', _Built} = relx:build_release(#{name => Name, vsn => Vsn}
                                       ,[{'output_dir', props:get_value('output_dir', Options)}
                                        | RelxConfig
                                        ]
                                       ),
    'ok'.

get_relx_config(Options) ->
    RelxConfigPath = props:get_value('config', Options),
    {'ok', Config0} = file:consult(RelxConfigPath),

    case props:get_value('script', Options) of
        'undefined' -> add_relx_script(Config0, script_path(RelxConfigPath));
        RelxScriptPath ->
            add_relx_script(Config0, RelxScriptPath)
    end.

script_path(RelxConfigPath) ->
    RelxScriptPath = <<RelxConfigPath/binary, ".script">>,
    case filelib:is_regular(RelxScriptPath) of
        'false' -> 'undefined';
        'true' -> RelxScriptPath
    end.

add_relx_script(Config0, 'undefined') -> Config0;
add_relx_script(Config0, RelxScriptPath) ->
    Bindings = erl_eval:add_binding('CONFIG', Config0, erl_eval:new_bindings()),
    {'ok', Config1} = file:script(RelxScriptPath, Bindings),
    Config1.

parse_args(CommandLineArgs) ->
    case getopt:parse(option_spec_list(), CommandLineArgs) of
        {'ok', {Options, Args}} when is_list(Options) ->
            {'ok', Options, Args};
        {'ok', {_O, _A}} ->
            print_help(1);
        {'error', {_O, _A}} ->
            print_help(1)
    end.

print_help(Exit) ->
    getopt:usage(option_spec_list(), escript:script_name()),
    halt(Exit).

-spec option_spec_list() -> list().
option_spec_list() ->
    [{'config', $c, "config", {'binary', <<"rel/relx.config">>}, "Path to relx.config"}
    ,{'script', $s, "script", 'undefined', "Path to relx.config.script"}
    ,{'V', $V, "verbose", {'integer', 1}, "Logging verbosity"}
    ,{'relname', $n, "relname", {'binary', <<"kazoo">>}, "Release name"}
    ,{'output_dir', $o, "output_dir", {'string', "_rel"}, "Output directory for the built release"}
    ].
