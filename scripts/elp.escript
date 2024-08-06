#!/usr/bin/env escript
%%! +A0 -sname elp_escript
%% -*- coding: utf-8 -*-

-mode('compile').

-export([main/1]).

%% API

main([RootDir, ProjectJSONFile]) ->
    SearchDir = filename:join([RootDir, "{core,applications}", "*", "src"]),
    io:format("searching ~s~n", [SearchDir]),

    SrcDirs = filelib:wildcard(SearchDir, RootDir),

    Apps = [add_dir(SrcDir) || SrcDir <- SrcDirs],

    DepsSearchDir = filename:join([RootDir, "deps", "*", "src"]),
    DepsDirs = filelib:wildcard(DepsSearchDir, RootDir),
    Deps = [add_dir(DepDir) || DepDir <- DepsDirs],

    JSON = kz_json:encode(kz_json:from_list([{<<"apps">>, Apps}
                                            ,{<<"deps">>, Deps}
                                            ])
                         ,['pretty']
                         ),
    file:write_file(ProjectJSONFile, JSON).

add_dir(SrcDir) ->
    AppDir = filename:dirname(SrcDir),
    App = filename:basename(AppDir),

    io:format("adding ~s: ~s~n", [App, AppDir]),
    SrcDirs = [kz_term:to_binary(string:replace(Dir, AppDir, <<>>))
               || Dir <- filelib:wildcard([AppDir, "/src/*"]), filelib:is_dir(Dir)
              ],

    kz_json:from_list([{<<"name">>, kz_term:to_binary(App)}
                      ,{<<"dir">>, kz_term:to_binary(AppDir)}
                      ,{<<"src_dirs">>, [<<"src">> | SrcDirs]}
                      ,{<<"extra_src_dirs">>, []}
                      ,{<<"ebin">>, kz_term:to_binary(filename:join([AppDir, "ebin"]))}
                      ,{<<"include_dirs">>, []}
                      ,{<<"macros">>, kz_json:new()}
                      ]).
