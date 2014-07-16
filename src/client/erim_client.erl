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

%% @author Jean Parpaillon <jean.parpaillon@free.fr>

%% @doc Callbacks based XMPP clients. Client argument is a module with the below callbacks.
%% Additional callbacls for specific IQ namespaces can be given in Opts
%%
%% Client callbacks:
%%   * init(Opts :: any(), Client :: pid() -> {ok, State :: any()} | {error, term()}.
%%
%% * presence
%%   * initial_presence(State :: any()) -> {erim_presence(), State}.
%%   * approve(Msg :: xmlel(), State :: any()) -> {ok, from, State} 
%%                                              | {ok, both, State}
%%                                              | {ok, none, State}
%%                                              | {error, term()}.
%%   * approved(Msg :: xmlel(), State :: any()) -> {ok, State} | {error, term()}.
%%
%% * message
%%   * msg_message(Msg :: xmlel(), State :: any()) -> {ok, State} | {error, term()}
%%   * msg_chat(Msg :: xmlel(), State :: any()) -> {ok, State} | {error, term()}
%%   * msg_group(Msg :: xmlel(), State :: any()) -> {ok, State} | {error, term()}
%%   * msg_headline(Msg :: xmlel(), State :: any()) -> {ok, State} | {error, term()}
%%   * msg_error(Msg :: xmlel(), State :: any()) -> {ok, State} | {error, term()}
%%   
-module(erim_client).
-compile({parse_transform, lager_transform}).

-behaviour(gen_server).

-include_lib("erim/include/erim.hrl").
-include_lib("erim/include/erim_client.hrl").

-define(CORE_CAPS, [?NS_CAPS]).

%% API
-export([start_link/2,
	 start_link/3,
	 send/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%%
%%% API
%%%
-spec start_link(Client :: atom(), Opts :: [erim_client_opt()]) -> 
			{ok, pid()} | {error, term()} | ignore.
start_link(Client, Opts) ->
    gen_server:start_link(?MODULE, [{client, Client} | Opts], []).

-spec start_link(Ref :: atom(), Client :: atom(), Opts :: [erim_client_opt()]) -> 
			{ok, pid()} | {error, term()} | ignore.
start_link(Ref, Client, Opts) ->
    gen_server:start_link({local, Ref}, ?MODULE, [{client, Client} | Opts], []).

-spec send(Ref :: pid(), Packet :: #xmlel{}) -> ok.
send(Ref, #xmlel{}=Packet) ->
    gen_server:cast(Ref, {send, Packet}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init(Opts) ->
    case proplists:get_value(creds, Opts) of
	undefined ->
	    {stop, missing_credentials};
	{#jid{}=Jid, Passwd} when is_binary(Passwd) ->
	    init_session(Opts, #erim_state{creds={Jid, Passwd}});
	{local, #jid{}=Jid} ->
	    init_local(Opts, #erim_state{creds={local, Jid}});
	Else ->
	    {stop, {invalid_credentials, Else}}
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Req, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast({send, #xmlel{}=Packet}, #erim_state{session=Session}=State) ->
    exmpp_session:send_packet(Session, Packet),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(#received_packet{packet_type=presence}=Pkt, State) ->
    lager:debug("Dispatching presence packet: ~p~n", [Pkt#received_packet.raw_packet]),
    case handle_presence(Pkt, State) of
	{ok, S2} ->
	    {noreply, S2};
	{error, Err} ->
	    {stop, Err, State};
	ignore -> 
	    lager:debug("Packet ignored: ~p~n", [Pkt#received_packet.raw_packet]),
	    {noreply, State}
    end;

handle_info(#received_packet{packet_type=message}=Pkt, State) ->
    lager:debug("Dispatching message packet: ~p~n", [Pkt#received_packet.raw_packet]),
    case handle_msg(Pkt, State) of
	{ok, S2} ->
	    {noreply, S2};
	{error, Err} ->
	    {stop, Err, State};
	ignore -> 
	    lager:debug("Packet ignored: ~p~n", [Pkt#received_packet.raw_packet]),
	    {noreply, State}
    end;

handle_info(#received_packet{packet_type=iq, queryns=NS, raw_packet=Raw}=_Pkt, State) ->
    lager:debug("Dispatching iq packet: ~p~n", [_Pkt#received_packet.raw_packet]),
    case call(NS, handle_iq, Raw, State) of
	{ok, _Ret, S2} ->
	    {noreply, S2};
	{error, Err} ->
	    {stop, Err, State};
	ignore ->
	    lager:debug("Packet ignored: ~p~n", [_Pkt#received_packet.raw_packet]),
	    {noreply, State}
    end;

handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%
%%% Priv
%%%
call({iq, NS}, Fun, Args, #erim_state{handlers=H}=S) ->
    case gb_trees:lookup(NS, H) of
	{value, {Handler, HandlerState}} ->
	    case Handler:Fun(Args, HandlerState) of
		{ok, HS2} ->
		    {ok, S#erim_state{handlers=gb_trees:update(NS, {Handler, HS2}, H)}};
		{ok, Ret, HS2} ->
		    {ok, Ret, S#erim_state{handlers=gb_trees:update(NS, {Handler, HS2}, H)}};
		{error, Err} ->
		    {error, Err}
	    end;
	undefined -> ignore
    end;
call(presence, Fun, Args, #erim_state{client=Mod, state=CS}=S) ->
    case Mod:Fun(Args, CS) of
	{error, Err} ->
	    {error, Err};
	{Ret, CS2} ->
	    {Ret, S#erim_state{state=CS2}}
    end;
call(message, Fun, Args, #erim_state{client=Mod, state=CS}=S) ->
    try Mod:Fun(Args, CS) of
	{error, Err} ->
	    {error, Err};
	{Ret, CS2} ->
	    {Ret, S#erim_state{state=CS2}}
    catch error:_Err ->
	    ignore
    end.

init_session(Opts, #erim_state{creds={Jid, Passwd}}=S) ->
    Session = exmpp_session:start(),
    exmpp_session:auth_basic_digest(Session, Jid, Passwd),
    S2 = S#erim_state{session=Session},
    case exmpp_session:connect_TCP(Session, proplists:get_value(server, Opts, "")) of
	{ok, _SId} ->
	    init_auth(S2, Opts);
	{ok, _SId, _F} ->
	    init_auth(S2, Opts);
	Else ->
	    {stop, {session_error, Else}}
    end.

init_auth(#erim_state{session=Session}=S, Opts) ->
    try exmpp_session:login(Session) of
	{ok, _Jid} -> 
	    case init_handler(Opts, S) of
		{ok, S2} -> 
		    init_presence(get_caps(S2));
		{error, Err} -> 
		    lager:error("Error initializing XMPP handlers: ~p~n", [Err]),
		    {stop, Err}
	    end
    catch throw:Err ->
	    {stop, Err}
    end.

init_local(Opts, #erim_state{}=S) ->
    lager:debug("Starting XMPP client with link-local mode~n", []),
    case init_handler(Opts, S) of
	{ok, S2} ->
	    init_advertisement(Opts, get_caps(S2));
	{error, Err} ->
	    lager:error("Error initializing XMPP handlers: ~p~n", [Err]),
	    {stop, Err}
    end.	    

init_advertisement(Opts, #erim_state{creds={local, Jid}, client=Client, state=CS, caps=Caps}=S) ->
    dnssd:start(),
    Name = proplists:get_value(name, Opts, ?ERIM_CLIENT_ID),
    Pres = case Client:initial_presence(CS) of
	       {#erim_presence{}=P, _CS2} -> P;
	       ignore -> #erim_presence{}
	   end,
    Txt = exmpp_presence:get_txt(proplists:get_value(node, Opts, S#erim_state.node),
				 Jid, Pres, Caps),
    lager:debug("Advertising ~s: ~p~n", [Name, Txt]),
    exmpp_dns:register_dnssd(Name, Txt),
    dnssd:stop(),
    {ok, S}.

init_handler(Opts, #erim_state{}=S) ->
    case proplists:get_value(client, Opts) of
	undefined -> throw(no_client_handler);
	Mod -> 
	    case Mod:init(Opts, self()) of
		{ok, ClientState} ->
		    init_handlers(Opts, S#erim_state{client=Mod, state=ClientState});
		{error, Err} ->
		    {error, Err}
	    end
    end.

init_handlers(Opts, #erim_state{}=S) ->
    case proplists:get_value(handlers, Opts) of
	undefined ->
	    {ok, S#erim_state{handlers=gb_trees:empty()}};
	H ->
	    init_handlers2(H, gb_trees:empty(), S)
    end.

init_handlers2([], Acc, S) ->
    {ok, S#erim_state{handlers=Acc}};
init_handlers2([{NS, Handler, Opts} | Rest], Acc, S) ->
    case Handler:init(Opts, self()) of
	{ok, HandlerState} ->
	    init_handlers2(Rest, gb_trees:insert(NS, {Handler, HandlerState}, Acc), S);
	{error, Err} ->
	    {error, {Handler, init_failed, Err}}
    end.

init_presence(#erim_state{session=Session, client=Client, state=CS, node=Node, caps=Caps}=State) ->
    case Client:initial_presence(CS) of
	{#erim_presence{}=P, CS2} ->
	    Pkt = exmpp_presence:available(P),
	    Pkt2 = exmpp_presence:set_capabilities(Pkt, Node, Caps),
	    exmpp_session:send_packet(Session, Pkt2),
	    {ok, State#erim_state{state=CS2}};
	ignore ->
	    Pkt = exmpp_presence:available(#erim_presence{}),
	    Pkt2 = exmpp_presence:set_capabilities(Pkt, Node, Caps),
	    exmpp_session:send_packet(Session, Pkt2),
	    {ok, State}
    end.

handle_presence(#received_packet{type_attr="subscribe", from=From, raw_packet=Raw}, 
	   #erim_state{session=Session}=State) ->
    case call(presence, approve, Raw, State) of
	{none, S2} -> 
	    {ok, S2};
	{from, S2} ->
	    Pkt = exmpp_presence:subscribed(exmpp_jid:make(From)),
	    exmpp_session:send_packet(Session, Pkt),
	    {ok, S2};
	{both, S2} ->
	    Pkt1 = exmpp_presence:subscribed(exmpp_jid:make(From)),
	    exmpp_session:send_packet(Session, Pkt1),
	    Pkt2 = exmpp_presence:subscribe(exmpp_jid:make(From)),
	    exmpp_session:send_packet(Session, Pkt2),
	    {ok, S2};
	{error, Err} ->
	    lager:error("Error in presence:approve callback: ~p~n", [Err]),
	    {error, Err}
    end;

handle_presence(#received_packet{type_attr="subscribed", raw_packet=Raw}, State) ->
    call(presence, approved, Raw, State);

handle_presence(#received_packet{type_attr="unsubscribe"},
	   #erim_state{}=State) ->
    {ok, State};

handle_presence(#received_packet{type_attr="unsubscribed"},
	   #erim_state{}=State) ->
    {ok, State};

handle_presence(#received_packet{type_attr="available"},
	   #erim_state{}=State) ->
    {ok, State};

handle_presence(#received_packet{type_attr="unavailable"},
	   #erim_state{}=State) ->
    {ok, State};

handle_presence(#received_packet{type_attr="probe"},
	   #erim_state{}=State) ->
    {ok, State};

handle_presence(#received_packet{type_attr="error"},
	   #erim_state{}=State) ->
    {ok, State}.

-spec handle_msg(#received_packet{}, #erim_state{}) -> {ok, #erim_state{}} | {error, term()}.
handle_msg(#received_packet{type_attr="normal", raw_packet=Raw}, State) ->
    call(message, msg_message, Raw, State);

handle_msg(#received_packet{type_attr="chat", raw_packet=Raw}, State) ->
    call(message, msg_chat, Raw, State);

handle_msg(#received_packet{type_attr="groupchat", raw_packet=Raw}, State) ->
    call(message, msg_group, Raw, State);

handle_msg(#received_packet{type_attr="headline", raw_packet=Raw}, State) ->
    call(message, msg_headline, Raw, State);

handle_msg(#received_packet{type_attr="error", raw_packet=Raw}, State) ->
    call(message, msg_error, Raw, State).

get_caps(#erim_state{handlers=H}=S) ->
    It = gb_trees:iterator(H),
    Features = get_features(gb_trees:next(It), []),
    S#erim_state{caps=Features}.

get_features(none, Acc) ->
    Acc;
get_features({Key, {_, _}, It}, Acc) ->
    get_features(gb_trees:next(It), [Key | Acc]).
