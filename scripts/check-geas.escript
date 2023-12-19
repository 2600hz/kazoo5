#!/usr/bin/env escript
%%! +A0 -sname kazoo_geas
%% -*- coding: utf-8 -*-


-mode('compile').

-export([main/1]).

%% API
maih([]) ->
    io:format("Please include paths to Erlang app directories~n"),
    halt(0);
main(["-a" | Paths]) ->
    main(Paths, 'false');
main(Paths) ->
    main(Paths, 'true').

main(Paths, PrintGlobal) ->
    {Is, Min, Max} = lists:foldl(fun info/2
                                ,{[], "0.0.0", "99.9.9"}
                                ,expand_paths(Paths)
                                ),
    PrintGlobal andalso io:format("OTP versions: ~s < KAZOO < ~s~n", [Min, Max]),

    print_app_vsns(lists:keysort(2, Is)).

print_app_vsns([{App, Min, Max} | Apps]) ->
    io:format("OTP versions: ~s < ~s~n", [Min, Max]),
    io:format("   ~-15s", [App]),
    print_app_vsns(Apps, Min, Max, 1).

print_app_vsns([], _, _, _) -> io:format("~n");
print_app_vsns([{App, Min, Max} | Apps], Min, Max, 5) ->
    io:format("~n   ~-15s", [App]),
    print_app_vsns(Apps, Min, Max, 1);
print_app_vsns([{App, Min, Max} | Apps], Min, Max, Printed) ->
    io:format(" ~-15s", [App]),
    print_app_vsns(Apps, Min, Max, Printed+1);
print_app_vsns([{App, Min, Max} | Apps], _, _, _Printed) ->
    io:format("~n~nOTP versions: ~s < ~s~n", [Min, Max]),
    io:format("  ~-15s", [App]),
    print_app_vsns(Apps, Min, Max, 1).

info(Path, {Vsns, Min, Max}) ->
    put(geas_exports,[]),
    try geas:info(kz_term:to_list(Path)) of
        {'ok', Results} ->
            Name = props:get_value('name', Results),
            {_, AppMin, AppMax, _} = props:get_value('compat', Results),
            {[{Name, geas_semver:versionize(AppMin), geas_semver:versionize(AppMax)} | Vsns]
            ,lists:max([Min, AppMin])
            ,lists:min([Max, AppMax])
            };
        {'error', _Msg, _ST} ->
            io:format("error on ~s: ~s~n", [Path, _Msg]),
            {Vsns, Min, Max}
    catch _E:_R:_ST ->
            {_E, _R, _ST}
    end.

expand_paths(Paths) ->
    [kz_term:to_list(P)
     || Path <- Paths,
        P <- expand_path(kz_term:to_binary(Path))
    ].

expand_path(Path) ->
    case filename:extension(Path) of
        <<>> -> maybe_expand_dir(Path);
        <<".erl">> -> maybe_expand_erl(Path);
        <<".beam">> -> [filename:dirname(filename:dirname(Path))]
    end.

maybe_expand_erl(Path) ->
    maybe_expand_erl(Path, filename:dirname(Path)).

maybe_expand_erl(_Path, DirName) ->
    AppDir = case filename:basename(DirName) of
                 <<"src">> ->
                     filename:dirname(DirName);
                 ParentDir ->
                     %% only two levels of nesting to find app dir of erlang code
                     <<"src">> = filename:basename(DirName),
                     filename:dirname(ParentDir)
             end,
    [AppDir].

maybe_expand_dir(Path) ->
    maybe_expand_dir(Path, filelib:is_dir(Path)).

maybe_expand_dir(_Path, 'false') -> [];
maybe_expand_dir(Path, 'true') ->
    case filename:basename(Path) of
        <<"ebin">> -> [filename:dirname(Path)];
        _AppName -> [Path]
    end.
