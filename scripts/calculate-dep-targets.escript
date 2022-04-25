#!/usr/bin/env escript
%%! +A0
%% -*- coding: utf-8 -*-

-mode('compile').

-export([main/1]).

%% DEBUG
%% -define(DBG(Fmt, Args), io:format(standard_io, "~p: "Fmt, [?LINE | Args])).

%% Prod
-define(DBG(_Fmt, _Args), 'ok').

%% API

main([KazooRoot, AppL]) ->
    ?DBG("starting at ~s for ~s~n", [KazooRoot, AppL]),
    App = list_to_atom(AppL),

    #{deps := AllDepApps} = calc(KazooRoot, App),
    [io:format(standard_io, "~s ", [A]) || A <- AllDepApps].

calc(KazooRoot, App) ->
    handle_application_loaded(App, application:load(App)),
    calc(KazooRoot, App, get_dep_apps(KazooRoot, App)).

handle_application_loaded(_App, 'ok') -> 'ok';
handle_application_loaded(App, {'error', {'already_loaded', App}}) -> 'ok';
handle_application_loaded(_App, {'error', _E}) ->
    ?DBG("error loading ~p: ~p~n", [_App, _E]).
%% stderr("failed to load ~s: ~p~n", [_App, E]).

calc(_KazooRoot, _App, {'error', 'not_found'}=E) ->
    stderr("dep apps not found for ~p~n", [_App]),
    E;
calc(KazooRoot, App, DepApps) ->
    calc(KazooRoot, App, DepApps, #{deps => [App], ignored => []}).

calc(_KazooRoot, _App, [], #{deps := AllDepApps}=AllDeps) ->
    AllDeps#{deps => lists:usort(AllDepApps)};
calc(KazooRoot, App, [DepApp | DepApps], AllDeps) when is_map(AllDeps) ->
    ?DBG("calc deps of app: ~p dep: ~p ~p~n", [App, DepApp, AllDeps]),
    WithDepsOfDep = calc_deps_of_dep(KazooRoot, App, DepApp, AllDeps),

    ?DBG("calclated deps of dep: ~p: ~p~n", [DepApp, WithDepsOfDep]),
    calc(KazooRoot, App, DepApps, WithDepsOfDep).

calc_deps_of_dep(KazooRoot, App, DepApp, #{deps := AllDepApps, ignored := Ignored}=AllDeps) ->
    ?DBG("app ~p dep ~p all: ~p ignored: ~p~n", [App, DepApp, AllDepApps, Ignored]),
    case lists:member(DepApp, AllDepApps)
        orelse lists:member(DepApp, Ignored)
    of
        'true' ->
            ?DBG("already added dep or ignored ~p~n", [DepApp]),
            AllDeps;
        'false' ->
            calc_deps_of_dep(KazooRoot, App, DepApp, AllDeps, is_kazoo_app(DepApp))
    end.

calc_deps_of_dep(_KazooRoot, _App, DepApp, #{ignored := Ignored}=AllDeps, 'false') ->
    ?DBG("ignoring ~p~n", [DepApp]),
    AllDeps#{ignored => [DepApp | Ignored]};
calc_deps_of_dep(KazooRoot, _App, DepApp, #{deps := AllDepApps, ignored := Ignored}=AllDeps, 'true') ->
    handle_application_loaded(DepApp, application:load(DepApp)),
    calc(KazooRoot, DepApp, get_dep_apps(KazooRoot, DepApp, Ignored), AllDeps#{deps => [DepApp | AllDepApps]}).

%%     {'error', 'not_found'} ->
%%         stderr("failed to find dep app ~p of parent app ~p: not found~n"
%%               ,[DepApp, App]
%%               ),
%%         {'error', 'not_found'};
%%     [] ->
%%         ?DBG("already calculated dep ~p, adding ~p~n", [DepApp, App]),
%%         AllDeps#{deps => [App | AllDepApps]};
%%     DepApps ->
%%         ?DBG("dep app ~s has ~p~n", [DepApp, DepApps]),
%%         AllDeps#{deps => lists:usort([App, DepApp | DepApps] ++ AllDepApps)}
%% end.

is_kazoo_app({'error', 'bad_name'}) -> 'false';
is_kazoo_app(App) when is_atom(App) ->
    is_kazoo_app(code:lib_dir(App));
is_kazoo_app(Path) when is_list(Path) ->
    'nomatch' =/= re:run(Path, "(core|applications)/").

get_dep_apps(KazooRoot, App) ->
    get_dep_apps(KazooRoot, App, []).

get_dep_apps(KazooRoot, App, Ignored) ->
    case application:get_key(App, 'applications') of
        {'ok', DepApps} ->
            ?DBG("dp: ~p ig: ~p: ~p~n", [DepApps, Ignored, DepApps -- Ignored]),
            DepApps -- Ignored;
        'undefined' -> consult_for_app_deps(KazooRoot, App) -- Ignored
    end.

consult_for_app_deps(KazooRoot, App) ->
    AppL = atom_to_list(App),
    case core_or_app(KazooRoot, AppL) of
        {'error', 'not_found'}=E -> E;
        CoreOrApp ->
            AppFile = filename:join([KazooRoot, CoreOrApp, AppL, "src", AppL ++ ".app.src"]),
            {'ok', [{'application', _App, Config}]} = file:consult(AppFile),
            proplists:get_value('applications', Config, [])
    end.

core_or_app(KazooRoot, AppL) ->
    core_or_app(KazooRoot, AppL, filelib:wildcard(KazooRoot ++ "/{core,applications,deps}/" ++ AppL)).

core_or_app(KazooRoot, AppL, []) ->
    stderr("failed to determine if ~s is core or dep in ~s~n", [AppL, KazooRoot]),
    {'error', 'not_found'};
core_or_app(_KazooRoot, _AppL, [Path]) ->
    filename:basename(filename:dirname(Path)).

stderr(Format, Args) ->
    io:format('standard_error', Format, Args).
