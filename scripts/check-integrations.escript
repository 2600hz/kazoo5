#!/usr/bin/env escript
%%! +A0 -sname kazoo_integrations
%% -*- coding: utf-8 -*-

%%% Builds, per-application, a mapping of app modules to called
%%% modules (and their app), writing to priv/integrations.config. That
%%% file is structured as a list of module/integration pairs where:

%%% module() = an app module of the current application
%%% integration() = #{called_modules = [{application_name(), module()}]
%%%                  ,integration_app => application() | 'undefined'
%%%                  }

%%% called_modules = list of {Erlang App, Module} of all remote
%%%   function calls
%%% integration_app = kazoo app this module integrates with (if any)
%%%   Modules will use the integration attribute in their source to
%%%   implicitly set this:
%%%   -integration(crossbar).
%%%   Folks can also explicitly update the priv/integrations.config
%%%   file with the app of choice

%%% Considering the 'skel' app we might see an integrations.config
%%% file looking like:

%%% [{bh_skel, #{called_modules = [{blackhole,bh_context}
%%%                               ,{blackhole,blackhole_bindings}
%%%                               ,{kazoo_stdlib,kz_binary}
%%%                               ]
%%%             }
%%%  }
%%%  ...
%%% ].

-mode('compile').

-export([main/1]).

%% API
main([IntegrationFile | Sources]) ->
    kz_integrations:process(IntegrationFile, Sources).
