#!/usr/bin/env escript
%%! +A0 -sname kazoo_xref
%% -*- coding: utf-8 -*-

-mode('compile').

-export([main/1]).

main([TagsFile]) ->
    main(TagsFile, code:which('kz_ast_util')).

main(_TagsFile, 'non_existing') ->
    io:format("failed to find applications/kazoo_ast, not generating TAGS~n"
              "add using:~necho \"DEPS += kazoo_ast~ndep_kazoo_ast = git https://github.com/2600hz/kazoo_ast master\" >> make/more_apps.mk~n"
             );
main(TagsFile, _File) ->
    AppDirs = lists:foldl(fun add_app_dirs/2, [], kz_ast_util:project_apps()),
    Paths = [AppPath || App <- lists:usort(AppDirs), AppPath <- [app_path(App)], AppPath =/= 'undefined'],
    tags:subdirs(Paths, [{'outfile', TagsFile}]).

add_app_dirs(App, Dirs) ->
    case lists:member(App, Dirs)
        orelse application:load(App)
    of
        'true' -> Dirs;
        'ok' ->
            add_app_dirs(App, Dirs, application:get_key(App, 'applications'));
        {'error', {'already_loaded', App}} ->
            add_app_dirs(App, Dirs, application:get_key(App, 'applications'));
        {'error', _E} ->
            io:format("failed to load app ~p: ~p~n", [App, _E]),
            Dirs
    end.

add_app_dirs(App, Dirs, {'ok', DepApps}) ->
    lists:usort(Dirs ++ [App | DepApps]);
add_app_dirs(_App, Dirs, _Else) ->
    io:format("failed to list dep apps for ~s: ~p~n", [_App, _Else]),
    Dirs.

app_path(App) ->
    app_path(App, lists:keyfind(App, 1, application:loaded_applications())).

app_path(App, {App, _, _}) ->
    case application:get_key(App, 'modules') of
        {'ok', [M | _]} ->
            filename:dirname(filename:dirname(code:which(M)));
        'undefined' ->
            AllKeys = application:get_all_key(App),
            io:format("  failed to find modules for ~s: ~p~n", [App, AllKeys]),
            'undefined'
    end;
app_path(_App, {'error', _}) -> 'undefined';
app_path(App, 'false') ->
    application:load(App),
    app_path(App, {App, 'ok', 'ok'}).
