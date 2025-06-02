#!/usr/bin/env escript
%%! +A0
%% -*- coding: utf-8 -*-

-mode('compile').

-export([main/1]).

%% API

main([RootL, AppRoot]) ->
    Root = kz_term:to_binary(RootL),
    MDs = filelib:wildcard(filename:join([AppRoot, "doc", "**", "*.md"])),

    Files = [re:replace(kz_term:to_binary(File), <<"(", Root/binary, "?/)">>, <<>>)
             || File <- MDs,
                'nomatch' =:= re:run(File, <<"/ref/">>)
            ],

    Index = filename:join([AppRoot, "doc", "dev.yml"]),
    create_index(app_header(AppRoot), Index, Files),
    'ok'.

create_index(App, Index, []) ->
    file:write_file(Index, ["  - '", App, "':\n"]);
create_index(App, Index, Files) ->
    YML = [  "  - '", App, "':\n"
          ,[["    - '", File, "'\n"] || File <- Files]
          ],
    'ok' = file:write_file(Index, YML).

app_header(AppRoot) ->
    App = filename:basename(AppRoot),
    [AppSrc] = filelib:wildcard(filename:join([AppRoot, "src", ["*.app.src"]])),

    case file:consult(AppSrc) of
        {'ok', [{'application', _App, Properties}]} ->
            props:get_value('description', Properties);
        {'error', 'enoent'} ->
            io:format('user', "Failed to read ~s app file ~s~n", [App, AppSrc]),
            exit({'error', 'enoent'})
    end.
