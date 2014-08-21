%% Copyright ProcessOne 2006-2010. All Rights Reserved.
%% Copyright Jean Parpaillon 2014. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.

%% @author Jean-Sébastien Pédron <js.pedron@meetic-corp.com>
%% @author Jean Parpaillon <jean.parpaillon@free.fr>

%% @doc
%% The module <strong>{@module}</strong> provides callbacks for
%% application(3) as well as some generic utilities for other modules of
%% this application.
%%
%% <p>
%% It's not intended to be used directly.
%% </p>

-module(exmpp).
-compile({parse_transform, lager_transform}).

-behaviour(application).

%% Initialization.
-export([
	 start/0,
	 version/0
	]).

%% application(3erl) callbacks.
-export([
	 start/2,
	 stop/1,
	 config_change/3
	]).

%% --------------------------------------------------------------------
%% Generic utilities.
%% --------------------------------------------------------------------

%% @spec () -> ok
%% @doc Start applications which exmpp depends on then start exmpp.

start() ->
    application:start(lager),
    application:start(erim_xml),
    application:start(erim).

%% @spec () -> Version
%%     Version = string()
%% @doc Return the version of the application.

version() ->
    {ok, Version} = application:get_key(erim, vsn),
    Version.

%% --------------------------------------------------------------------
%% application(3erl) callbacks.
%% --------------------------------------------------------------------

%% @hidden

start(_Start_Type, _Start_Args) ->
    exmpp_sup:start_link().

%% @hidden

stop(_State) ->
    ok.

%% @hidden

config_change(Changed, New, Removed) ->
    lager:error("Config change:~n"
		"Changed: ~p~n"
		"New: ~p~n"
		"Removed: ~p~n",
		[Changed, New, Removed]),
    ok.
