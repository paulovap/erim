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
-ifndef(erim_hrl).
-define(erim_hrl, true).

% Namespace and prefix macros.
-include("erim_nss.hrl").

% Records to represent XML elements.
-include_lib("erim_xml/include/erim_xml.hrl").

% Records to represent XMPP/Jabber specific structures.
-include("erim_xmpp.hrl").

% Records to represent Caps.
-include("erim_caps.hrl").

% Logging macros
-include("erim_log.hrl").

% --------------------------------------------------------------------
% Records to represent events.
% --------------------------------------------------------------------

% Stream start.
-record(xmlstreamstart, {
  element                 % #xmlel
}).

% Depth 1 element, inside a stream.
-record(xmlstreamelement, {
  element                 % #xmlel
}).

% Stream end.
-record(xmlstreamend, {
  endtag                  % xmlnsendelement
}).

-endif.
