#!/usr/bin/env escript
%%! +A0 -sname kazoo_dialyzer
%% -*- coding: utf-8 -*-

%% Reads arguments, finds unknown remote types, and checks if those
%% types exist in the remote module.

-mode('compile').

-export([main/1]).

%% API

main([]) ->
    print_help(1);
main([KazooPLT | Paths]) ->
    handle(KazooPLT, Paths).

-spec print_help(integer()) -> no_return().
print_help(Halt) ->
    Script = escript:script_name(),
    io:format("ERL_LIBS=deps/:core/:applications/ ~s .kazoo.plt [file.beam | path/ebin/ ...]~n", [Script]),
    halt(Halt).

handle(_PLT, []) -> 'ok';
handle(KazooPLT, Paths) ->
    ".plt" = filename:extension(KazooPLT),

    Env = string:tokens(os:getenv("TO_DIALYZE", ""), " "),
    handle_paths(KazooPLT, filter_for_erlang_files(lists:usort(Env ++ Paths))).

handle_paths(_KazooPLT, []) ->
    io:format('standard_err', "No Erlang files found to process~n", []),
    print_help(0);
handle_paths(KazooPLT, Paths) ->
    MissingTypes = find_unknown_types(KazooPLT, Paths),
    halt(MissingTypes).

find_unknown_types(KazooPLT, Paths) ->
    ScanResults = do_scan_unknown(KazooPLT, Paths),
    {MissingTypes, _Types} = lists:foldl(fun handle_scan_result/2, {#{}, #{}}, ScanResults),
    print_and_count_missing_types(MissingTypes).

print_and_count_missing_types(MissingTypes) ->
    SortedTypes = lists:keysort(1, maps:to_list(MissingTypes)),
    lists:foldl(fun print_and_count_missing_type/2, 0, SortedTypes).

print_and_count_missing_type({{Mod, Type, Arity}, Count}, Acc) ->
    print_missing_type({Mod, Type, Arity}, Count, Acc),
    Acc+1.

print_missing_type({Mod, Type, Arity}, Count, 0) ->
    io:format("  missing types:~n"),
    print_missing_type({Mod, Type, Arity}, Count, 1);
print_missing_type({Mod, Type, Arity}, Count, _) ->
    io:format("    ~p:~p/~p ref'd ~s~n", [Mod, Type, Arity, count_times(Count)]).

count_times(1) ->
    "1 time";
count_times(N) ->
    [kz_term:to_list(N), " times"].

handle_scan_result({'warn_unknown',_,{'unknown_type',{Module,Type,Arity}}}=Warn
                  ,{MissingTypes, ModTypes}
                  ) ->
    case maps:get(Module, ModTypes, 'undefined') of
        'undefined' ->
            Types = get_module_exported_types(Module),
            handle_scan_result(Warn, {MissingTypes, ModTypes#{Module => Types}});
        Types ->
            case lists:member({Type, Arity}, Types) of
                'true' -> {MissingTypes, ModTypes};
                'false' ->
                    {maps:update_with({Module, Type, Arity}
                                     ,fun increment/1
                                     ,1
                                     ,MissingTypes
                                     )
                    ,ModTypes
                    }
            end
    end;
handle_scan_result(_ScanResult, Acc) -> Acc.

increment(N) -> N+1.

get_module_exported_types(Module) ->
    get_module_exported_types(Module, kz_ast_util:module_ast(Module)).

get_module_exported_types(Module, {Module, {'raw_abstract_v1', Attributes}}) ->
    lists:flatten([Types || {'attribute',_,'export_type',Types} <- Attributes]);
get_module_exported_types(Module, 'undefined') ->
    io:format('standard_error', "Missing AST for ~p~n", [Module]),
    [].

do_scan_unknown(KazooPLT, Paths) ->
    [io:format('standard_io', "  ~s~n", [Path]) || Path <- Paths],
    dialyzer:run([{'init_plt', KazooPLT}
                 ,{'analysis_type', 'succ_typings'}
                  %% ,{'files_rec', [Path]}
                 ,{'from', 'byte_code'}
                 ,{'files', Paths}
                 ,{'warnings', ['unknown']}
                 ]).

filter_for_erlang_files(Files) ->
    lists:foldl(fun filter_for_erlang_file/2, [], Files).

filter_for_erlang_file(File, Paths) ->
    filter_is_file(File, Paths, filelib:is_file(File)).

filter_is_file(_File, Paths, 'false') ->
    Paths;
filter_is_file(File, Paths, 'true') ->
    filter_test(File, Paths, is_test(File)).

filter_test(_File, Paths, 'true') -> Paths;
filter_test(File, Paths, 'false') ->
    filter_non_erlang(File
                     ,Paths
                     ,is_ebin_dir(File)
                     ,is_beam(File)
                     ,is_erl(File)
                     ).

filter_non_erlang(File, Paths, 'true', 'false', 'false') ->
    %% add ebin
    [File | Paths];
filter_non_erlang(File, Paths, 'false', 'true', 'false') ->
    %% add beam
    case filelib:is_regular(File) of
        'true' -> [File | Paths];
        'false' ->
            io:format("failed to find ~s~n", [File]),
            Paths
    end;
filter_non_erlang(File, Paths, 'false', 'false', 'true') ->
    %% add .erl
    filter_non_erlang(to_beam(File), Paths, 'false', 'true', 'false');
filter_non_erlang(_File, Paths, _, _, _) -> Paths.

to_beam(Erl) ->
    to_beam(filename:basename(Erl, ".erl"), filename:split(Erl), []).

to_beam(Module, ["src" | _], PathRev) ->
    filename:join(lists:reverse(PathRev) ++ ["ebin", Module ++ ".beam"]);
to_beam(Module, [Segment | Segments], PathRev) ->
    to_beam(Module, Segments, [Segment | PathRev]).

%% Internals

is_test(Path) ->
    lists:member("test", string:tokens(Path, "/")).

is_erl(Path) ->
    ".erl" == filename:extension(Path).

is_beam(Path) ->
    ".beam" == filename:extension(Path).

is_ebin_dir(Path) ->
    "ebin" == filename:basename(Path).
