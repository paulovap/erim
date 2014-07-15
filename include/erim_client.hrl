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
-ifndef(erim_client_hrl).
-define(erim_client_hrl, true).

-include("erim_xml.hrl").
-include("erim_jid.hrl").

-define(ERIM_CLIENT_ID, <<"erim">>).
-define(ERIM_CLIENT_URL, <<"https://github.com/jeanparpaillon/erim">>).

%% This record is used to pass received packets back to client.
%% The record is defined to make it easy to use pattern matching on
%% the most used data received.
-record(received_packet,
        {
          packet_type, % message, iq, presence
          type_attr,   % depend on packet. Example: set, get, subscribe, etc
          from,        % JID
          id,          % Packet ID
          queryns,     % IQ only: Namespace of the query
          raw_packet   % raw exmpp record
        }).
-type(received_packet() :: #received_packet{}).

-type(erim_match() :: xmlname()).
-type(erim_handler() :: {Match :: erim_match(), Handler :: atom(), Opts :: any()}).
-type(erim_creds() :: {Jid :: jid(), Passwd :: binary()} | {local, jid()}).

-type(erim_client_category() :: client).
-type(erim_client_opt() :: {creds, erim_creds()} 
			 | {handlers, [erim_handler()]}
			 | {name, binary()}
			 | {node, binary()}
			 | {category, erim_client_category()}
			 | {type, binary()}).

-record(erim_state, {session        :: pid(),
		     jid            :: jid(),
		     client         :: atom(),
		     state          :: term(),
		     caps           :: erim_caps(),
		     handlers       :: [erim_handler()]}).
-type(erim_state() :: #erim_state{}).

-record(erim_caps, {name         = ?ERIM_CLIENT_ID     :: binary(),
		    node         = ?ERIM_CLIENT_URL    :: binary(),
		    category     = client              :: erim_client_category(),
		    type         = <<"pc">>            :: binary(),
		    features     = []                  :: [xmlname()]}).
-type(erim_caps() :: #erim_caps{}).

-record(erim_presence, {show        = chat             :: chat | away | xa | dnd,
			status      = <<>>             :: binary(),
			priority    = 1                :: integer(),
			caps        = undefined        :: erim_caps()}).
-type(erim_presence() :: #erim_presence{}).

-endif.
