#!/usr/bin/env escript
%%! +A0 -sname kazoo_dialyzer
%% -*- coding: utf-8 -*-

-mode('compile').

-export([main/1]).

%% API

main([]) ->
    print_help(1);
main([KazooPLT | CommandLineArgs]) ->
    {'ok', Options, Args} = parse_args(CommandLineArgs),

    %% Dialyzer being Dialyzer and is not writing the output to the provided output file
    %% when it is called programmatically. It always returns the warning. So we need to do
    %% it manually and print the output ourself.
    %%
    %% Just fyi, calling dialyzer directly from CLI works, it just calling
    %% `dialyzer:run/1' won't.
    {OutFilename, OutFile} = init_output(Options),
    WarnResult = handle(KazooPLT, Options, OutFile, Args),
    log_warn_result(OutFile, WarnResult),
    maybe_close_output_file(OutFilename, OutFile),
    halt(WarnResult).

parse_args(CommandLineArgs) ->
    case getopt:parse(option_spec_list(), CommandLineArgs) of
        {'ok', {Options, Args}} when is_list(Options) ->
            {'ok', Options, Args};
        {'ok', {_O, _A}} ->
            print_help(1);
        {'error', {_O, _A}} ->
            print_help(1)
    end.

-spec option_spec_list() -> list().
option_spec_list() ->
    [{'help', $?, "help", 'undefined', "Show the program options"}
    ,{'hard', $h, "hard", {'boolean', 'false'}, "Include remote modules called by the supplied modules"}
    ,{'bulk', $b, "bulk", {'boolean', 'false'}, "Dialyze all files together (requires more memory/CPU)"}
    ,{'output_file', $o, "output-file", {'string', 'undefined'}, "Also write the Dialyzer analysis results to the specified outfile."}
    ].

-spec print_help(integer()) -> no_return().
print_help(Halt) ->
    Script = escript:script_name(),
    getopt:usage(option_spec_list(), "ERL_LIBS=deps/:core/:applications/ " ++ Script ++ " .kazoo.plt [args] [file.beam | path/ebin/ ...]"),
    halt(Halt).

handle(KazooPLT, Options, OutFile, Args) ->
    ".plt" = filename:extension(KazooPLT),

    Env = string:tokens(os:getenv("TO_DIALYZE", ""), " "),

    handle_paths(KazooPLT
                ,Options
                ,OutFile
                ,filter_for_erlang_files(lists:usort(Env ++ Args))
                ).

handle_paths(_KazooPLT, _Options, OutFile, []) ->
    output_write(OutFile, io_lib:format("No Erlang files found to process\n", [])),
    0;
handle_paths(KazooPLT, Options, OutFile, Paths) ->
    warn(KazooPLT, Options, Paths, OutFile).

log_warn_result(OutFile, 1) ->
    output_write(OutFile, io_lib:format("1 Dialyzer warning~n", []));
log_warn_result(OutFile, Count) ->
    output_write(OutFile, io_lib:format("~p Dialyzer warnings~n", [Count])).

init_output(Options) ->
    case props:get_value('output_file', Options) of
        'undefined' ->
            {'standard_io', 'standard_io'};
        OutFile ->
            case file:open(OutFile, ['write']) of
                {'ok', IoFile} ->
                    %% Warnings and errors can include Unicode characters.
                    'ok' = io:setopts(IoFile, [{'encoding', 'unicode'}]),
                    io:format("saving dialyzer output to ~ts~n", [OutFile]),
                    {OutFile, IoFile};
                {'error', Reason} ->
                    io:format("could not open output file ~tp, Reason: ~p\n", [OutFile, Reason]),
                    halt(1)
            end
    end.

maybe_close_output_file(_, 'standard_io') -> 'ok';
maybe_close_output_file(OutFilename, File) ->
    io:format("~n~ncheck output file `~ts' for details~n", [OutFilename]),
    _ = file:close(File),
    'ok'.

filter_for_erlang_files(Files) ->
    [Arg || Arg <- Files,
            not is_test(Arg)
                andalso (
                  is_ebin_dir(Arg)
                  orelse is_beam(Arg)
                  orelse is_erl(Arg)
                 )
                andalso filelib:is_file(Arg)
    ].

%% Internals

is_test(Path) ->
    lists:member("test", string:tokens(Path, "/")).

is_erl(Path) ->
    ".erl" == filename:extension(Path).

is_beam(Path) ->
    ".beam" == filename:extension(Path).

is_ebin_dir(Path) ->
    "ebin" == filename:basename(Path).

root_dir("/"++Path) ->
    filename:join(["/" | lists:takewhile(fun is_not_src/1
                                        ,string:tokens(Path, "/")
                                        )
                  ]
                 );
root_dir(Path) ->
    filename:join(lists:takewhile(fun is_not_src/1
                                 ,string:tokens(Path, "/")
                                 )
                 ).

is_not_src("src") -> 'false';
is_not_src(_) -> 'true'.

file_exists(Filename) ->
    case file:read_file_info(Filename) of
        {'ok', _}           -> 'true';
        {'error', 'enoent'} -> 'false';
        {'error', _Reason}  -> 'false';
        _ -> 'false'
    end.

warn(PLT, Options, Paths, OutFile) ->
    GoHard = props:get_value('hard', Options),
    Bulk = GoHard
        orelse props:get_value('bulk', Options),

    %% take the beams in Paths and run a dialyzer pass to get unknown functions
    %% add the modules from unknown functions
    %% then run do_warm without GoHard
    {BeamPaths, GoHard} = lists:foldl(fun get_beam_path/2, {[], GoHard}, Paths),

    AllModules = find_unknown_modules(PLT, BeamPaths, GoHard),

    log_work_to_do(BeamPaths, AllModules, GoHard, OutFile),
    do_warn(PLT, AllModules, Bulk, OutFile).

log_work_to_do([BeamPath], _AllModules, 'false', OutFile) ->
    output_write(OutFile, io_lib:format("analyzing 1 path...~n~tp~n~n", [BeamPath]));
log_work_to_do(BeamPaths, _AllModules, 'false', OutFile) ->
    output_write(OutFile, io_lib:format("analyzing ~tp paths...~n", [length(BeamPaths)])),
    _ = [log_file_to_do(File, OutFile) || File <- lists:usort(BeamPaths)],
    output_write(OutFile, io_lib:format("~n", []));
log_work_to_do(BeamPaths, AllModules, 'true', OutFile) ->
    Len = length(BeamPaths),
    output_write(OutFile, io_lib:format("analyzing ~tp paths + ~tp called modules...~n~n", [Len, length(AllModules)-Len])),
    _ = [output_write(OutFile, io_lib:format("~ts~n", [File])) || File <- lists:usort(BeamPaths ++ AllModules)],
    output_write(OutFile, io_lib:format("\n", [])),
    'ok'.

log_file_to_do({'app', Files}, OutFile) ->
    [log_file_to_do(File, OutFile) || File <- Files];
log_file_to_do(File, OutFile) ->
    output_write(OutFile, io_lib:format("~ts~n", [File])).

find_unknown_modules(_PLT, BeamPaths, 'false') -> BeamPaths;
find_unknown_modules(PLT, BeamPaths, 'true') ->
    handle_scan_results(BeamPaths, do_scan_unknown(PLT, BeamPaths)).

handle_scan_results(BeamPaths, ScanResults) ->
    lists:foldl(fun maybe_add_unknown_module/2, BeamPaths, ScanResults).

maybe_add_unknown_module({'warn_unknown', _, {'unknown_function',{Module, _Function, _Arity}}}
                        ,BeamPaths
                        ) ->
    maybe_add_unknown_module(Module, BeamPaths);
maybe_add_unknown_module({'warn_unknown',_,{'unknown_type',{Module,_Type,_Arity}}}
                        ,BeamPaths
                        ) ->
    maybe_add_unknown_module(Module, BeamPaths);
maybe_add_unknown_module({_Warning, _, _}, BeamPaths) -> BeamPaths;

maybe_add_unknown_module('localtime', BeamPaths) -> BeamPaths;
maybe_add_unknown_module(Module, BeamPaths) when is_atom(Module) ->
    maybe_add_unknown_module(Module, BeamPaths, code:which(Module)).


maybe_add_unknown_module(_Module, BeamPaths, 'non_existing') ->
    BeamPaths;
maybe_add_unknown_module(_Module, BeamPaths, 'preloaded') ->
    BeamPaths;
maybe_add_unknown_module(_Module, BeamPaths, MPath) ->
    [fix_path(MPath) | BeamPaths].

get_beam_path(Path, {BPs, GoHard}) ->
    {maybe_fix_path(Path, BPs, GoHard), GoHard}.

maybe_fix_path(Path, BPs, GoHard) ->
    case {is_beam(Path), is_erl(Path)} of
        {'true', 'false'} ->
            [fix_path(Path) | BPs];
        {'false', 'true'} ->
            RootDir = root_dir(Path),
            Module  = filename:basename(Path, ".erl"),
            Beam = filename:join([RootDir, "ebin", Module++".beam"]),
            case file_exists(Beam) of
                'true' -> [fix_path(Beam) | BPs];
                'false' -> BPs
            end;
        {'false', 'false'} when GoHard ->
            lists:foldl(fun(F, Acc) -> maybe_fix_path(F, Acc, GoHard) end
                       ,BPs
                       ,filelib:wildcard(filename:join(Path, "*.beam"))
                       );
        {'false', 'false'} ->
            [{'app', filelib:wildcard(filename:join(Path, "*.beam"))} | BPs]
    end.

fix_path(Path) ->
    {'ok', CWD} = file:get_cwd(),
    fix_path(Path, CWD).

fix_path('non_existing', _CWD) -> 'undefined';
fix_path('preloaded', _CWD) -> 'undefined';
fix_path(Path, CWD) ->
    case re:run(Path, CWD) of
        'nomatch' -> filename:join([CWD, Path]);
        _ -> Path
    end.

do_warn(PLT, Paths, InBulk, OutFile) ->
    {Apps, Beams} = maybe_separate_steps(Paths, InBulk),

    {N, _PLT, InBulk, _} = lists:foldl(fun do_warn_path/2
                                      ,{0, PLT, InBulk, OutFile}
                                      ,[{'beams', Beams} | Apps]
                                      ),
    N.

maybe_separate_steps(Paths, InBulk) ->
    lists:foldl(fun(Path, Acc) -> maybe_separate_step(Path, Acc, InBulk) end
               ,{[], []}
               ,Paths
               ).

maybe_separate_step({'app', AppFiles}, {Apps, Beams}, 'true') ->
    {Apps, AppFiles ++ Beams};
maybe_separate_step({'app', AppFiles}, {Apps, Beams}, 'false') ->
    {[{'app', AppFiles} | Apps], Beams};
maybe_separate_step({'beam', Bs}, {Apps, Beams}, _InBulk) ->
    {Apps, Bs ++ Beams};
maybe_separate_step(Beam, {Apps, Beams}, _InBulk) ->
    {Apps, [Beam | Beams]}.

%% explicitly adding `kz_types' so dialyzer knows about
%% `sup_init_ret', `handle_call_ret_state' and other supervisor,
%% gen_server, ... critical types defined in `kz_types'. Dialyzer is
%% strict about types for these `init', `handle_*' functions and if we
%% don't add `kz_types' here, Dialyzer thinks their types are `any()'
%% and will warn about it.
ensure_kz_types(Beams) ->
    case lists:any(fun(F) -> filename:basename(F, ".beam") =:= "kz_types" end, Beams) of
        'true' -> lists:usort(Beams);
        'false' -> lists:usort([code:which('kz_types') | Beams])
    end.

do_warn_path({_, []}, Acc) -> Acc;
do_warn_path({_, Beams}, {N, PLT, 'true', OutFile}) ->
    {N + scan_and_print(PLT, Beams, OutFile), PLT, 'true', OutFile};
do_warn_path({Type, Beams}, {N, PLT, 'false', OutFile}) ->
    try lists:split(5, Beams) of
        {Ten, Rest} ->
            do_warn_path({Type, Rest}
                        ,{N + scan_and_print(PLT, Ten, OutFile), PLT, 'false', OutFile}
                        )
    catch
        'error':'badarg' ->
            {N + scan_and_print(PLT, Beams, OutFile), PLT, 'false', OutFile}
    end.

scan_and_print(PLT, Bs, OutFile) ->
    Beams = ensure_kz_types(Bs),
    length([print(Beams, W, OutFile)
            || W <- scan(PLT, Beams),
               filter(W)
           ]).

filter({'warn_contract_supertype',  _, _}) -> 'false';
filter({'warn_undefined_callbacks', _, _}) -> 'false';
filter({'warn_contract_types',      _, {'overlapping_contract',_}}) -> 'false';
filter({'warn_umatched_return',     _, {'unmatched_return', ["'ok' | {'error','lager_not_running' | {'sink_not_configured'," ++ _]}}) -> 'false';
filter({'warn_unmatched_return',    _, {'unmatched_return', ["'false' | 'ok' | {'error','lager_not_running' | {'sink_not_configured'," ++ _]}}) -> 'false';
filter({'warn_umatched_return',     _, {'unmatched_return',["'ok' | {'error','invalid_db_name'}"]}}) -> 'false';
filter({'warn_return_no_exit',      _, {'no_return',['only_normal','kz_log_md_clear',0]}}) -> 'false';
filter({'warn_failing_call',        _, {'call',['lager','md',"([])" | _]}}) -> 'false';
filter(_W) -> 'true'.

print(Beams, {Tag, {"src/" ++ _=File, {Line, _Col}}, _W}=Warning, OutFile) ->
    Filename = filename:basename(File, ".erl"),
    case [Beam || Beam <- Beams, Filename =:= filename:basename(Beam, ".beam")] of
        [] ->
            output_write(OutFile, io_lib:format("failed to find beam for ~ts~n", [File]));
        [Beam] ->
            AppDir = filename:dirname(filename:dirname(Beam)),
            SrcFile = filename:join([AppDir, File]),
            output_write(OutFile
                        ,io_lib:format("~ts:~tp: ~ts~n  ~ts~n"
                                      ,[SrcFile, Line, Tag
                                       ,dialyzer:format_warning(Warning, [{'error_location', 'line'}])]
                                      )
                        )
    end;
print(_Beams, {Tag, {File, Line}, _W}=Warning, OutFile) ->
    output_write(OutFile
                ,io_lib:format("uk: ~ts:~tp: ~ts~n  ~ts~n"
                              ,[File, Line, Tag
                               ,dialyzer:format_warning(Warning, [{'error_location', 'line'}])
                               ]
                              )
                );
print(_Beams, _Err, OutFile) ->
    output_write(OutFile, io_lib:format("error: ~tp~n", [_Err])).

output_write('standard_io', Msg) ->
    io:format(Msg);
output_write(OutFile, Msg) ->
    io:format(Msg),
    io:format(OutFile, "~ts", [Msg]).

scan(PLT, Things) ->
    try do_scan(PLT, Things) of
        Ret -> Ret
    catch
        _E:{'dialyzer_error', Error} ->
            io:format('standard_error', "crash dialyzer_error: ~s\n", [Error]),
            [];
        _E:_T:_ST ->
            io:format('standard_error', "dialyzer crash: ~p:~p~n~p~n", [_E, _T, _ST]),
            []
    end.

do_scan_unknown(PLT, Paths) ->
    dialyzer:run([{'init_plt', PLT}
                 ,{'analysis_type', 'succ_typings'}
                  %% ,{'files_rec', [Path]}
                 ,{'from', 'byte_code'}
                 ,{'files', Paths}
                 ,{'warnings', ['unknown']}
                 ]).

do_scan(PLT, Paths) ->
    dialyzer:run([{'init_plt', PLT}
                 ,{'analysis_type', 'succ_typings'}
                  %% ,{'files_rec', [Path]}
                 ,{'from', 'byte_code'}
                 ,{'files', Paths}
                 ,{'warnings', ['error_handling' %% functions that only return via exception
                                %% ,no_behaviours  %% suppress warnings about behaviour callbacks
                                %% ,no_contracts   %% suppress warnings about invalid contracts
                                %% ,no_fail_call   %% suppress warnings for failing calls
                                %% ,no_fun_app     %% suppress warnings for failing fun applications
                                %% ,no_improper_lists %% suppress warnings for improper list construction
                                %% ,no_match          %% suppress warnings for patterns that are unused
                                %% ,'no_missing_calls'  %% suppress warnings about calls to missing functions
                                %% ,no_opaque         %% suppress warnings for violating opaque data structures
                                %% ,no_return         %% suppress warnings for functions that never return a value
                                %% ,no_undefined_callbacks %% suppress warnings about behaviours with no -callback
                                %% ,no_unused         %% suppress warnings for unused functions
                                %% ,'race_conditions'   %% include warnings for possible race conditions
                               ,'underspecs'        %% warn when the spec is too loose
                               ,'no_unknown'           %% let warnings about unknown functions/types change exit status
                               ,'unmatched_returns' %% warn when function calls ignore structure return values
                               ,'no_extra_return' %% ignore functions that have too-permissive specs
                                %% ,overspecs %% ignorable, mostly for Dialyzer devs
                                %% ,specdiffs
                               ]}
                 ]).

%% End of Module
