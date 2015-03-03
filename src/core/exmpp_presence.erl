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
%% The module <strong>{@module}</strong> provides helpers to do presence
%% common operations.

-module(exmpp_presence).

-include("erim.hrl").
-include("erim_client.hrl").

%% avoid name clash with local error/2 function
-compile({no_auto_import,[error/2]}).

%% Presence creation.
-export([presence/2,
	 available/1,
	 available/0,
	 unavailable/0,
	 subscribe/0,
	 subscribe/1,
	 subscribed/0,
	 subscribed/1,
	 unsubscribe/0,
	 unsubscribed/0,
	 probe/0,
	 error/2]).

%% Presence standard attributes.
-export([is_presence/1,
	 get_type/1,
	 set_type/2,
	 get_show/1,
	 set_show/2,
	 get_status/1,
	 set_status/2,
	 get_priority/1,
	 set_priority/2,
	 get_capabilities/1,
	 set_capabilities/3,
	 get_txt/4]).

-define(EMPTY_PRESENCE, #xmlel{ns = ?NS_JABBER_CLIENT, name = 'presence'}).

%% --------------------------------------------------------------------
%% Type definitions.
%% --------------------------------------------------------------------

-type(presencetype() ::
      available    |
      unavailable  |
      subscribe    |
      subscribed   |
      unsubscribe  |
      unsubscribed |
      probe        |
      error
     ).

-type(presenceshow() ::
      online |
      away   |
      chat   |
      dnd    |
      xa
     ).

%% --------------------------------------------------------------------
%% Presence creation.
%% --------------------------------------------------------------------

%% @spec (Type, Status) -> Presence
%%     Type = available | unavailable | subscribe | subscribed | unsubscribe | unsubscribed | probe | error
%%     Status = string() | binary()
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza with given type and status.

-spec presence(presencetype(), binary() | string()) -> xmlel().
presence(Type, Status) ->
    set_status(set_type(?EMPTY_PRESENCE, Type), Status).

-spec available(erim_presence()) -> #xmlel{}.
available(#erim_presence{show=Show, status=Status, priority=Pri}) ->
    set_priority(
      set_status(
	set_show(?EMPTY_PRESENCE, Show), Status), Pri).

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the sender is available.
-spec available() -> xmlel().
available() ->
    ?EMPTY_PRESENCE.

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the sender is not available.
-spec unavailable() -> xmlel().
unavailable() ->
    set_type(?EMPTY_PRESENCE, "unavailable").

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the sender wants to
%% subscribe to the receiver's presence.
-spec subscribe() -> xmlel().
subscribe() ->
    set_type(?EMPTY_PRESENCE, "subscribe").

%% @spec (Jid) -> Presence
%%     To = #jid{}.
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the sender wants to
%% subscribe to the receiver's presence.
-spec subscribe(To :: #jid{}) -> xmlel().
subscribe(#jid{}=To) ->
    exmpp_stanza:set_recipient(set_type(?EMPTY_PRESENCE, "subscribe"), To).

%% @spec (To) -> Presence
%%     To = #jid{}
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the receiver was
%% subscribed from the sender's presence.
-spec subscribed(To :: #jid{}) -> xmlel().
subscribed(#jid{}=To) ->
    exmpp_stanza:set_recipient(set_type(?EMPTY_PRESENCE, "subscribed"), To).

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the receiver was
%% subscribed from the sender's presence.
-spec subscribed() -> xmlel().
subscribed() ->
    set_type(?EMPTY_PRESENCE, "subscribed").

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the sender wants to
%% unsubscribe to the receiver's presence.
-spec unsubscribe() -> xmlel().
unsubscribe() ->
    set_type(?EMPTY_PRESENCE, "unsubscribe").

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a presence stanza to tell that the receiver was
%% unsubscribed from the sender's presence.
-spec unsubscribed() -> xmlel().
unsubscribed() ->
    set_type(?EMPTY_PRESENCE, "unsubscribed").

%% @spec () -> Presence
%%     Presence = erim_xml:xmlel()
%% @doc Create a probe presence stanza.
-spec probe() -> xmlel().
probe() ->
    set_type(?EMPTY_PRESENCE, "probe").

%% @spec (Presence, Error) -> New_Presence
%%     Presence = erim_xml:xmlel()
%%     Error = erim_xml:xmlel() | atom()
%%     New_Presence = erim_xml:xmlel()
%% @doc Prepare a presence stanza to notify an error.
%%
%% If `Error' is an atom, it must be a standard condition defined by
%% XMPP Core.
-spec error(xmlel(), xmlel() | atom()) -> xmlel().
error(Presence, Condition) when is_atom(Condition) ->
    Error = exmpp_stanza:error(Presence#xmlel.ns, Condition),
    error(Presence, Error);
error(Presence, Error) when ?IS_PRESENCE(Presence) ->
    exmpp_stanza:reply_with_error(Presence, Error).

%% --------------------------------------------------------------------
%% Presence standard attributes.
%% --------------------------------------------------------------------

%% @spec (El) -> bool
%%     El = erim_xml:xmlel()
%% @doc Tell if `El' is a presence.
%%
%% You should probably use the `IS_PRESENCE(El)' guard expression.
-spec is_presence(xmlel()) -> boolean().
is_presence(Presence) when ?IS_PRESENCE(Presence) -> true;
is_presence(_El)                                  -> false.

%% @spec (Presence) -> Type
%%     Presence = erim_xml:xmlel()
%%     Type = available | unavailable | subscribe | subscribed | unsubscribe | unsubscribed | probe | error | undefined
%% @doc Return the type of the given presence stanza.
-spec get_type(xmlel()) -> presencetype() | undefined.
get_type(Presence) when ?IS_PRESENCE(Presence) ->
    case exmpp_stanza:get_type(Presence) of
        undefined          -> 'available';
        <<"unavailable">>  -> 'unavailable';
        <<"subscribe">>    -> 'subscribe';
        <<"subscribed">>   -> 'subscribed';
        <<"unsubscribe">>  -> 'unsubscribe';
        <<"unsubscribed">> -> 'unsubscribed';
        <<"probe">>        -> 'probe';
        <<"error">>        -> 'error';
        _                  -> undefined
    end.

%% @spec (Presence, Type) -> New_Presence
%%     Presence = erim_xml:xmlel()
%%     Type = available | unavailable | subscribe | subscribed | unsubscribe | unsubscribed | probe | error | binary() | string()
%%     New_Presence = erim_xml:xmlel()
%% @doc Set the type of the given presence stanza.
-spec set_type(xmlel(), presencetype() | binary() | string()) -> xmlel().
set_type(Presence, <<>>) when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_attribute(Presence, <<"type">>);
set_type(Presence, "") when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_attribute(Presence, <<"type">>);
set_type(Presence, 'available') when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_attribute(Presence, <<"type">>);
set_type(Presence, <<"available">>) when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_attribute(Presence, <<"type">>);
set_type(Presence, "available") when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_attribute(Presence, <<"type">>);

set_type(Presence, Type) when is_binary(Type) ->
    set_type(Presence, binary_to_list(Type));
set_type(Presence, Type) when is_list(Type) ->
    set_type(Presence, list_to_atom(Type));

set_type(Presence, Type) when ?IS_PRESENCE(Presence), is_atom(Type) ->
    Type_B = case Type of
		 'unavailable'  -> <<"unavailable">>;
		 'subscribe'    -> <<"subscribe">>;
		 'subscribed'   -> <<"subscribed">>;
		 'unsubscribe'  -> <<"unsubscribe">>;
		 'unsubscribed' -> <<"unsubscribed">>;
		 'probe'        -> <<"probe">>;
		 'error'        -> <<"error">>;
		 _              -> throw({presence, set_type, invalid_type, Type})
	     end,
    exmpp_stanza:set_type(Presence, Type_B).

%% @spec (Presence) -> Show | undefined
%%     Presence = erim_xml:xmlel()
%%     Show = online | away | chat | dnd | xa | undefined
%% @doc Return the show attribute of the presence.
-spec get_show(xmlel()) -> presenceshow() | undefined.
get_show(#xmlel{ns = NS} = Presence) when ?IS_PRESENCE(Presence) ->
    case erim_xml:get_element(Presence, NS, 'show') of
        undefined ->
            'online';
        Show_El ->
            case exmpp_utils:strip(erim_xml:get_cdata(Show_El)) of
                <<"away">> -> 'away';
                <<"chat">> -> 'chat';
                <<"dnd">>  -> 'dnd';
                <<"xa">>   -> 'xa';
                _          -> undefined
            end
    end.

%% @spec (Presence, Show) -> New_Presence
%%     Presence = erim_xml:xmlel()
%%     Show = online | away | chat | dnd | xa | binary() | string()
%%     New_Presence = erim_xml:xmlel()
%% @doc Set the `<show/>' field of a presence stanza.
%%
%% If `Type' is an empty string or the atom `online', the `<show/>'
%% element is removed.
-spec set_show(xmlel(), presenceshow() | binary() | string()) -> xmlel().
set_show(#xmlel{ns = NS} = Presence, <<>>) when ?IS_PRESENCE(Presence)->
    erim_xml:remove_element(Presence, NS, 'show');
set_show(#xmlel{ns = NS} = Presence, "") when ?IS_PRESENCE(Presence)->
    erim_xml:remove_element(Presence, NS, 'show');
set_show(#xmlel{ns = NS} = Presence, 'online')
  when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_element(Presence, NS, 'show');
set_show(#xmlel{ns = NS} = Presence, <<"online">>)
  when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_element(Presence, NS, 'show');
set_show(#xmlel{ns = NS} = Presence, "online")
  when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_element(Presence, NS, 'show');

set_show(Presence, Show) when is_binary(Show) ->
    set_show(Presence, binary_to_list(Show));
set_show(Presence, Show) when is_list(Show) ->
    set_show(Presence, list_to_atom(Show));

set_show(#xmlel{ns = NS} = Presence, Show)
  when ?IS_PRESENCE(Presence), is_atom(Show) ->
    Show_B = case Show of
		 'away' -> <<"away">>;
		 'chat' -> <<"chat">>;
		 'dnd'  -> <<"dnd">>;
		 'xa'   -> <<"xa">>;
		 _      -> throw({presence, set_show, invalid_show, Show})
	     end,
    New_Show_El = erim_xml:set_cdata(#xmlel{ns = NS, name = 'show'}, Show_B),
    case erim_xml:get_element(Presence, NS, 'show') of
        undefined ->
            erim_xml:append_child(Presence, New_Show_El);
        Show_El ->
            erim_xml:replace_child(Presence, Show_El, New_Show_El)
    end.

%% @spec (Presence) -> Status | undefined
%%     Presence = erim_xml:xmlel()
%%     Status = binary()
%% @doc Return the status attribute of the presence.
-spec get_status(xmlel()) -> binary() | undefined.
get_status(#xmlel{ns = NS} = Presence) when ?IS_PRESENCE(Presence) ->
    case erim_xml:get_element(Presence, NS, 'status') of
        undefined ->
            undefined;
        Status_El ->
            erim_xml:get_cdata(Status_El)
    end.

%% @spec (Presence, Status) -> New_Presence
%%     Presence = erim_xml:xmlel()
%%     Status = string() | binary()
%%     New_Presence = erim_xml:xmlel()
%% @doc Set the `<status/>' field of a presence stanza.
%%
%% If `Status' is an empty string (or an empty binary), the previous
%% status is removed.
-spec set_status(xmlel(), binary() | string() | undefined) -> xmlel().
set_status(#xmlel{ns = NS} = Presence, undefined)
  when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_element(Presence, NS, 'status');
set_status(#xmlel{ns = NS} = Presence, <<>>) when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_element(Presence, NS, 'status');
set_status(#xmlel{ns = NS} = Presence, "") when ?IS_PRESENCE(Presence) ->
    erim_xml:remove_element(Presence, NS, 'status');
set_status(#xmlel{ns = NS} = Presence, Status) when ?IS_PRESENCE(Presence) ->
    New_Status_El = erim_xml:set_cdata(#xmlel{ns = NS, name = 'status'},
					Status),
    case erim_xml:get_element(Presence, NS, 'status') of
        undefined ->
            erim_xml:append_child(Presence, New_Status_El);
        Status_El ->
            erim_xml:replace_child(Presence, Status_El, New_Status_El)
    end.

%% @spec (Presence) -> Priority
%%     Presence = erim_xml:xmlel()
%%     Priority = integer()
%% @doc Return the priority attribute of the presence.
-spec get_priority(xmlel()) -> integer().
get_priority(#xmlel{ns = NS} = Presence) when ?IS_PRESENCE(Presence) ->
    case erim_xml:get_element(Presence, NS, 'priority') of
        undefined ->
            0;
        Priority_El ->
            case erim_xml:get_cdata_as_list(Priority_El) of
                "" -> 0;
                P  -> list_to_integer(P)
            end
    end.

%% @spec (Presence, Priority) -> New_Presence
%%     Presence = erim_xml:xmlel()
%%     Priority = integer()
%%     New_Presence = erim_xml:xmlel()
%% @doc Set the `<priority/>' field of a presence stanza.
-spec set_priority(xmlel(), integer()) -> xmlel().
set_priority(#xmlel{ns = NS} = Presence, Priority)
  when ?IS_PRESENCE(Presence) andalso is_integer(Priority) ->
    New_Priority_El = erim_xml:set_cdata(#xmlel{ns = NS, name = 'priority'},
					  Priority),
    case erim_xml:get_element(Presence, NS, 'priority') of
        undefined ->
            erim_xml:append_child(Presence, New_Priority_El);
        Priority_El ->
            erim_xml:replace_child(Presence, Priority_El, New_Priority_El)
    end.

%% @spec (Presence) -> Capabilities
%%     Presence = erim_xml:xmlel()
%%     Capabilities = xmlel()
%% @doc Return the capabilities of a presence
-spec get_capabilities(xmlel()) -> #xmlel{}.
get_capabilities(#xmlel{} = Presence) when ?IS_PRESENCE(Presence) ->
    case erim_xml:get_element(Presence, ?NS_CAPS, 'c') of
	undefined -> undefined;
	#xmlel{}=E -> E
    end.


%% @spec (Presence, Capabilities) -> New_Presence
%%     Presence = erim_xml:xmlel()
%%     Capabilities = erim_caps()
%%     New_Presence = erim_xml:xmlel()
%% @doc Set the `<c/>' element of a presence stanza.
-spec set_capabilities(xmlel(), binary(), list()) -> xmlel().
set_capabilities(#xmlel{}=Presence, Node, Caps)
  when ?IS_PRESENCE(Presence) ->
    C = erim_xml:element(?NS_CAPS, c, 
			  [erim_xml:attribute(<<"hash">>, <<"sha-1">>),
			   erim_xml:attribute(<<"node">>, Node),
			   erim_xml:attribute(<<"ver">>, get_capabilities_version(Caps))], 
			  []),
    erim_xml:append_child(Presence, C).

-spec get_txt(Node :: binary(), Jid :: #jid{}, erim_presence(), Features :: [atom()]) -> term().
get_txt(Node, #jid{}=Jid, #erim_presence{}=Pres, Features) ->
    {ok, Hostname} = inet:gethostname(),
    LocalJid = << (Jid#jid.node)/binary, "@", (list_to_binary(Hostname))/binary >>,
    [{txtvers, "1"},
     {hash, 'sha-1'},
     {jid, LocalJid},
     {node, Node},
     {'port.p2pj', "5562"},
     {status, Pres#erim_presence.status},
     {ver, get_capabilities_version(Features)}
    ].


%%%
%%% Private
%%%
get_capabilities_version(Features) ->
    base64:encode(crypto:hash(sha, cat_features(Features, []))).

cat_features([], Acc) ->
    lists:reverse(Acc);
cat_features([F | Rest], Acc) when is_atom(F) ->
    cat_features(Rest, [atom_to_list(F) | Acc]);
cat_features([F | Rest], Acc) when is_binary(F) orelse is_list(F) ->
    cat_features(Rest, [F | Acc]).
