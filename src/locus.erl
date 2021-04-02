%% Copyright (c) 2017-2021 Guilherme Andrade
%%
%% Permission is hereby granted, free of charge, to any person obtaining a
%% copy  of this software and associated documentation files (the "Software"),
%% to deal in the Software without restriction, including without limitation
%% the rights to use, copy, modify, merge, publish, distribute, sublicense,
%% and/or sell copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
%% DEALINGS IN THE SOFTWARE.
%%
%% locus is an independent project and has not been authorized, sponsored,
%% or otherwise approved by MaxMind.

-module(locus).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_loader/2]).                -ignore_xref({start_loader,2}).
-export([start_loader/3]).                -ignore_xref({start_loader,3}).
-export([stop_loader/1]).                 -ignore_xref({stop_loader,1}).
-export([loader_child_spec/2]).           -ignore_xref({loader_child_spec,2}).
-export([loader_child_spec/3]).           -ignore_xref({loader_child_spec,3}).
-export([loader_child_spec/4]).           -ignore_xref({loader_child_spec,4}).
-export([await_loader/1]).                -ignore_xref({await_loader,1}).
-export([await_loader/2]).                -ignore_xref({await_loader,2}).
-export([await_loaders/2]).               -ignore_xref({await_loaders,2}).
-export([lookup/2]).                      -ignore_xref({lookup,2}).
-export([get_info/1]).                    -ignore_xref({get_info,1}).
-export([get_info/2]).                    -ignore_xref({get_info,2}).
-export([analyze/1]).                     -ignore_xref({analyze,1}).

-ifdef(TEST).
-export([parse_database_edition/1]).
-endif.

%% ------------------------------------------------------------------
%% Deprecated API Function Exports
%% ------------------------------------------------------------------

-export([wait_for_loader/1]).             -ignore_xref({wait_for_loader,1}).
-export([wait_for_loader/2]).             -ignore_xref({wait_for_loader,2}).
-export([wait_for_loaders/2]).            -ignore_xref({wait_for_loaders,2}).
-export([get_version/1]).                 -ignore_xref({get_version,1}).

-deprecated([{wait_for_loader,1,eventually}]).
-deprecated([{wait_for_loader,2,eventually}]).
-deprecated([{wait_for_loaders,2,eventually}]).
-deprecated([{get_version,1,eventually}]).

%% ------------------------------------------------------------------
%% CLI-only Function Exports
%% ------------------------------------------------------------------

-ifdef(ESCRIPTIZING).
-export([main/1]).                        -ignore_xref({main,1}).
-endif.

%% ------------------------------------------------------------------
%% Macro Definitions
%% ------------------------------------------------------------------

-define(might_be_chardata(V), (is_binary((V)) orelse ?is_proper_list((V)))).
-define(is_proper_list(V), (length((V)) >= 0)).

%% ------------------------------------------------------------------
%% Type Definitions
%% ------------------------------------------------------------------

-type database_edition() :: maxmind_database_edition().
-export_type([database_edition/0]).

-type maxmind_database_edition() ::
    {maxmind, atom() | unicode:chardata()} |
    legacy_maxmind_database_edition().
-export_type([maxmind_database_edition/0]).

-type legacy_maxmind_database_edition() :: atom().
-export_type([legacy_maxmind_database_edition/0]).

-type database_url() :: unicode:chardata().
-export_type([database_url/0]).

-type database_error() :: database_unknown | database_not_loaded.
-export_type([database_error/0]).

-type database_entry() :: locus_mmdb:lookup_success().
-export_type([database_entry/0]).

-type ip_address_prefix() :: locus_mmdb:ip_address_prefix().
-export_type([ip_address_prefix/0]).

-type database_info() ::
    #{ metadata := database_metadata(),
       source := database_source(),
       version := database_version()
     }.
-export_type([database_info/0]).

-type database_metadata() :: locus_mmdb:metadata().
-export_type([database_metadata/0]).

-type database_source() :: locus_loader:source().
-export_type([database_source/0]).

-type database_version() :: calendar:datetime().
-export_type([database_version/0]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

%% @doc Like `:start_loader/3' but with default options
%%
%% <ul>
%% <li>`DatabaseId' must be an atom.</li>
%% <li>`DatabaseEdition' must be a `database_edition()' tuple; alternatively, `DatabaseURL'
%% must be a string or a binary representing a HTTP(s) URL or local path.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`ok' in case of success.</li>
%% <li>`{error, invalid_url}' if the source is invalid.</li>
%% <li>`{error, already_started}' if the loader under `DatabaseId' has already been started.</li>
%% </ul>
%% @see await_loader/1
%% @see await_loader/2
%% @see start_loader/1
%% @see start_loader/3
-spec start_loader(DatabaseId, DatabaseEdition | DatabaseURL) -> ok | {error, Error}
            when DatabaseId :: atom(),
                 DatabaseEdition :: database_edition(),
                 DatabaseURL :: database_url(),
                 Error :: invalid_url | already_started | application_not_running.
start_loader(DatabaseId, DatabaseEditionOrURL) ->
    start_loader(DatabaseId, DatabaseEditionOrURL, []).

%% @doc Starts a database loader under id `DatabaseId' with options `Opts'.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom.</li>
%% <li>`DatabaseEdition' must be a `database_edition()' tuple; alternatively, `DatabaseURL'
%% must be a string or a binary representing a HTTP(s) URL or local path.</li>
%% <li>`Opts' must be a list of `locus_database:opt()' values</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`ok' in case of success.</li>
%% <li>`{error, invalid_url}' if the source is invalid.</li>
%% <li>`{error, already_started}' if the loader under `DatabaseId' has already been started.</li>
%% </ul>
%% @see await_loader/1
%% @see await_loader/2
%% @see start_loader/1
%% @see start_loader/2
-spec start_loader(DatabaseId, DatabaseEdition | DatabaseURL, Opts) -> ok | {error, Error}
            when DatabaseId :: atom(),
                 DatabaseEdition :: database_edition(),
                 DatabaseURL :: database_url(),
                 Opts :: [locus_database:opt()],
                 Error :: (invalid_url | already_started |
                           {invalid_opt,term()} | application_not_running).
start_loader(DatabaseId, DatabaseEdition, Opts)
  when is_tuple(DatabaseEdition); is_atom(DatabaseEdition) ->
    Origin = parse_database_edition(DatabaseEdition),
    OptsWithDefaults = opts_with_defaults(Opts),
    locus_database:start(DatabaseId, Origin, OptsWithDefaults);
start_loader(DatabaseId, DatabaseURL, Opts)
  when ?might_be_chardata(DatabaseURL) ->
    case parse_url(DatabaseURL) of
        false ->
            {error, invalid_url};
        Origin ->
            OptsWithDefaults = opts_with_defaults(Opts),
            locus_database:start(DatabaseId, Origin, OptsWithDefaults)
    end.

%% @doc Stops the database loader under id `DatabaseId'.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% </ul>
%%
%% Returns `ok' in case of success, `{error, not_found}' otherwise.
-spec stop_loader(DatabaseId) -> ok | {error, Error}
            when DatabaseId :: atom(),
                 Error :: not_found.
stop_loader(DatabaseId) ->
    locus_database:stop(DatabaseId).

%% @doc Like `:loader_child_spec/2' but with default options
%%
%% <ul>
%% <li>`DatabaseId' must be an atom.</li>
%% <li>`DatabaseEdition' must be a `database_edition()' tuple; alternatively, `DatabaseURL'
%% must be a string or a binary representing a HTTP(s) URL or local path.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>A `supervisor:child_spec()'.</li>
%% </ul>
%% @see loader_child_spec/1
%% @see loader_child_spec/3
%% @see await_loader/1
%% @see await_loader/2
%% @see start_loader/2
-spec loader_child_spec(DatabaseId, DatabaseEdition | DatabaseURL) -> ChildSpec | no_return()
            when DatabaseId :: atom(),
                 DatabaseEdition :: database_edition(),
                 DatabaseURL :: database_url(),
                 ChildSpec :: locus_database:static_child_spec().
loader_child_spec(DatabaseId, DatabaseEditionOrURL) ->
    loader_child_spec(DatabaseId, DatabaseEditionOrURL, []).

%% @doc Like `:loader_child_spec/3' but with default child id
%%
%% <ul>
%% <li>`DatabaseId' must be an atom.</li>
%% <li>`DatabaseEdition' must be a `database_edition()' tuple; alternatively, `DatabaseURL'
%% must be a string or a binary representing a HTTP(s) URL or local path.</li>
%% <li>`Opts' must be a list of `locus_database:opt()' values</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>A `supervisor:child_spec()'.</li>
%% </ul>
%% @see loader_child_spec/3
%% @see loader_child_spec/4
%% @see await_loader/1
%% @see await_loader/2
%% @see start_loader/3
-spec loader_child_spec(DatabaseId, DatabaseEdition | DatabaseURL, Opts) -> ChildSpec | no_return()
            when DatabaseId :: atom(),
                 DatabaseEdition :: database_edition(),
                 DatabaseURL :: database_url(),
                 Opts :: [locus_database:opt()],
                 ChildSpec :: locus_database:static_child_spec().
loader_child_spec(DatabaseId, DatabaseEditionOrURL, Opts) ->
    loader_child_spec({locus_database,DatabaseId}, DatabaseId, DatabaseEditionOrURL, Opts).

%% @doc Returns a supervisor child spec for a database loader under id `DatabaseId' with options `Opts'.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom.</li>
%% <li>`DatabaseEdition' must be a `database_edition()' tuple; alternatively, `DatabaseURL'
%% must be a string or a binary representing a HTTP(s) URL or local path.</li>
%% <li>`Opts' must be a list of `locus_database:opt()' values</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>A `supervisor:child_spec()'.</li>
%% </ul>
%% @see loader_child_spec/3
%% @see await_loader/1
%% @see await_loader/2
%% @see start_loader/3
-spec loader_child_spec(ChildId, DatabaseId, DatabaseEdition | DatabaseURL, Opts)
        -> ChildSpec | no_return()
            when ChildId :: term(),
                 DatabaseId :: atom(),
                 DatabaseEdition :: database_edition(),
                 DatabaseURL :: database_url(),
                 Opts :: [locus_database:opt()],
                 ChildSpec :: locus_database:static_child_spec().
loader_child_spec(ChildId, DatabaseId, DatabaseEdition, Opts)
  when is_tuple(DatabaseEdition); is_atom(DatabaseEdition) ->
    Origin = parse_database_edition(DatabaseEdition),
    OptsWithDefaults = opts_with_defaults(Opts),
    locus_database:static_child_spec(ChildId, DatabaseId, Origin, OptsWithDefaults);
loader_child_spec(ChildId, DatabaseId, DatabaseURL, Opts)
  when ?might_be_chardata(DatabaseURL) ->
    case parse_url(DatabaseURL) of
        false ->
            error(invalid_url);
        Origin ->
            OptsWithDefaults = opts_with_defaults(Opts),
            locus_database:static_child_spec(ChildId, DatabaseId, Origin, OptsWithDefaults)
    end.

%% @doc Like `await_loader/1' but with a default timeout of 30 seconds.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, LoadedVersion}' when the database is ready to use.</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, {database_stopped, _}}' if the database loader for `DatabaseId' stopped while we waited.</li>
%% <li>`{error, {timeout, [_]}}' if all the load attempts performed before timing out have failed.</li>
%% </ul>
%% @see await_loader/2
-spec await_loader(DatabaseId) -> {ok, LoadedVersion} | {error, Reason}
            when DatabaseId :: atom(),
                 LoadedVersion :: database_version(),
                 Reason :: (database_unknown |
                            {database_stopped, term()} |
                            {timeout, LoadAttemptFailures}),
                 LoadAttemptFailures :: [term()].
await_loader(DatabaseId) ->
    await_loader(DatabaseId, 30000).

%% @doc Blocks caller execution until either readiness is achieved or the default timeout is triggered.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% <li>`Timeout' must be either a non-negative integer (milliseconds) or `infinity'.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, LoadedVersion}' when the database is ready to use.</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, {database_stopped, _}}' if the database loader for `DatabaseId' stopped while we waited.</li>
%% <li>`{error, {timeout, [_]}}' if all the load attempts performed before timing out have failed.</li>
%% </ul>
%% @see await_loader/1
%% @see await_loaders/2
-spec await_loader(DatabaseId, Timeout) -> {ok, LoadedVersion} | {error, Reason}
            when DatabaseId :: atom(),
                 Timeout :: timeout(),
                 LoadedVersion :: database_version(),
                 Reason :: (database_unknown |
                            {database_stopped, term()} |
                            {timeout, LoadAttemptFailures}),
                 LoadAttemptFailures :: [term()].
await_loader(DatabaseId, Timeout) ->
    case await_loaders([DatabaseId], Timeout) of
        {ok, #{DatabaseId := LoadedVersion}} ->
            {ok, LoadedVersion};
        {error, {#{DatabaseId := Reason}, _}} ->
            {error, Reason}
    end.

%% <ul>
%% <li>`DatabaseIds' must be a list of atoms that refer to database loaders.</li>
%% <li>`Timeout' must be either a non-negative integer (milliseconds) or `infinity'.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, #{DatabaseId => LoadedVersion}}' when all the databases are ready to use.</li>
%% <li>`{error, {DatabaseId, database_unknown}}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, {DatabaseId, {loading, term()}}}' if loading `DatabaseId' failed for some reason.</li>
%% <li>`{error, timeout}' if we've given up on waiting.</li>
%% </ul>

%% @doc Like `await_loader/2' but it can concurrently await status from more than one database.
%%
%% <ul>
%% <li>`DatabaseIds' must be list of atom referring to database loaders.</li>
%% <li>`Timeout' must be either a non-negative integer (milliseconds) or `infinity'.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, #{DatabaseId => LoadedVersion}}' when all the database are ready to use.</li>
%% <li>`{error, {#{DatabaseId => ErrorReason}, _}}' in case of errors.</li>
%% </ul>
%% @see await_loader/2
-spec await_loaders(DatabaseIds, Timeout) -> ({ok, Successes} |
                                              {error, {ErrorPerDatabase, PartialSuccesses}})
            when DatabaseIds :: [DatabaseId],
                 Timeout :: timeout(),
                 Successes :: LoadedVersionPerDatabase,
                 PartialSuccesses :: LoadedVersionPerDatabase,
                 LoadedVersionPerDatabase :: #{DatabaseId => LoadedVersion},
                 LoadedVersion :: database_version(),
                 ErrorPerDatabase :: #{DatabaseId := Reason},
                 Reason :: (database_unknown |
                            {database_stopped, term()} |
                            {timeout, LoadAttemptFailures}),
                 LoadAttemptFailures :: [term()].
await_loaders(DatabaseIds, Timeout) ->
    ReplyRef = make_ref(),
    UniqueDatabaseIds = lists:usort(DatabaseIds),
    WaiterOpts = [],
    Waiters = [{DatabaseId, locus_waiter:start(ReplyRef, DatabaseId, Timeout, WaiterOpts)}
               || DatabaseId <- UniqueDatabaseIds],
    EmulateLegacyBehaviour = false,
    perform_wait(ReplyRef, Waiters, #{}, #{}, EmulateLegacyBehaviour).

%% @doc Looks-up info on IPv4 and IPv6 addresses.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% <li>`Address' must be either an `inet:ip_address()' tuple, or a string/binary
%%    containing a valid representation of the address.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, Entry}' in case of success</li>
%% <li>`{error, not_found}' if no data was found for this `Address'.</li>
%% <li>`{error, invalid_address}' if `Address' is not either a `inet:ip_address()'
%%    tuple or a valid textual representation of an IP address.</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, database_not_loaded}' if the database hasn't yet been loaded.</li>
%% <li>`{error, ipv4_database}' if `Address' represents an IPv6 address and the database
%%      only supports IPv4 addresses.</li>
%% </ul>
-spec lookup(DatabaseId, Address) -> {ok, Entry} | {error, Error}
            when DatabaseId :: atom(),
                 Address :: inet:ip_address() | nonempty_string() | binary(),
                 Entry :: database_entry(),
                 Error :: (not_found | invalid_address |
                           database_unknown | database_not_loaded |
                           ipv4_database).
lookup(DatabaseId, Address) ->
    locus_mmdb:lookup(DatabaseId, Address).

%% @doc Returns the properties of a currently loaded database.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, database_info()}' in case of success</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, database_not_loaded}' if the database hasn't yet been loaded.</li>
%% </ul>
%% @see get_info/2
-spec get_info(DatabaseId) -> {ok, Info} | {error, Error}
            when DatabaseId :: atom(),
                 Info :: database_info(),
                 Error :: database_unknown | database_not_loaded.
get_info(DatabaseId) ->
    case locus_mmdb:get_parts(DatabaseId) of
        {ok, Parts} ->
            {ok, info_from_db_parts(Parts)};
        {error, Error} ->
            {error, Error}
    end.

%% @doc Returns a specific property of a currently loaded database.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% <li>`Property' must be either `metadata', `source' or `version'.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, Value}' in case of success</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, database_not_loaded}' if the database hasn't yet been loaded.</li>
%% </ul>
%% @see get_info/1
-spec get_info(DatabaseId, Property) -> {ok, Value} | {error, Error}
            when DatabaseId :: atom(),
                 Property :: metadata | source | version,
                 Value :: database_metadata() | database_source() | database_version(),
                 Error :: database_unknown | database_not_loaded.
get_info(DatabaseId, Property) ->
    case get_info(DatabaseId) of
        {ok, Info} ->
            Value = maps:get(Property, Info),
            {ok, Value};
        {error, Error} ->
            {error, Error}
    end.

%% @doc Analyzes a loaded database for corruption or incompatibility.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`ok' if the database is wholesome</li>
%% <li>`{error, {flawed, [Flaw, ...]]}}' in case of corruption or incompatibility
%%    (see the definition of {@link locus_mmdb:analysis_flaw/0})
%% </li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, database_not_loaded}' if the database hasn't yet been loaded.</li>
%% </ul>
-spec analyze(DatabaseId) -> ok | {error, Error}
            when DatabaseId :: atom(),
                 Error :: ({flawed, [locus_mmdb:analysis_flaw(), ...]} |
                           database_unknown |
                           database_not_loaded).
analyze(DatabaseId) ->
    locus_mmdb:analyze(DatabaseId).

%% ------------------------------------------------------------------
%% Deprecated API Function Definitions
%% ------------------------------------------------------------------

%% @doc Blocks caller execution until either readiness is achieved or a database load attempt fails.
%% @deprecated Use {@link await_loader/1} instead.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, LoadedVersion}' when the database is ready to use.</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, {loading, term()}}' if loading the database failed for some reason.</li>
%% </ul>
-spec wait_for_loader(DatabaseId) -> {ok, LoadedVersion} | {error, Error}
            when DatabaseId :: atom(),
                 LoadedVersion :: database_version(),
                 Error :: database_unknown | {loading, LoadingError},
                 LoadingError :: term().
wait_for_loader(DatabaseId) ->
    wait_for_loader(DatabaseId, infinity).

%% @doc Like `wait_for_loader/1' but it can time-out.
%% @deprecated Use {@link await_loader/2} instead.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% <li>`Timeout' must be either a non-negative integer (milliseconds) or `infinity'.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, LoadedVersion}' when the database is ready to use.</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, {loading, term()}}' if loading the database failed for some reason.</li>
%% <li>`{error, timeout}' if we've given up on waiting.</li>
%% </ul>
-spec wait_for_loader(DatabaseId, Timeout) -> {ok, LoadedVersion} | {error, Reason}
            when DatabaseId :: atom(),
                 Timeout :: timeout(),
                 LoadedVersion :: database_version(),
                 Reason :: database_unknown | {loading,term()} | timeout.
wait_for_loader(DatabaseId, Timeout) ->
    case wait_for_loaders([DatabaseId], Timeout) of
        {ok, #{DatabaseId := LoadedVersion}} ->
            {ok, LoadedVersion};
        {error, {DatabaseId, Reason}} ->
            {error, Reason};
        {error, timeout} ->
            {error, timeout}
    end.

%% @doc Like `wait_for_loader/2' but it can concurrently await status from more than one database.
%% @deprecated Use {@link await_loaders/2} instead.
%%
%% <ul>
%% <li>`DatabaseIds' must be a list of atoms that refer to database loaders.</li>
%% <li>`Timeout' must be either a non-negative integer (milliseconds) or `infinity'.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, #{DatabaseId => LoadedVersion}}' when all the databases are ready to use.</li>
%% <li>`{error, {DatabaseId, database_unknown}}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, {DatabaseId, {loading, term()}}}' if loading `DatabaseId' failed for some reason.</li>
%% <li>`{error, timeout}' if we've given up on waiting.</li>
%% </ul>
-spec wait_for_loaders(DatabaseIds, Timeout) -> {ok, LoadedVersionPerDatabase} | {error, Reason}
            when DatabaseIds :: [DatabaseId],
                 Timeout :: timeout(),
                 LoadedVersionPerDatabase :: #{DatabaseId => LoadedVersion},
                 LoadedVersion :: database_version(),
                 Reason ::{DatabaseId,LoaderFailure} | timeout,
                 LoaderFailure :: database_unknown | {loading,term()}.
wait_for_loaders(DatabaseIds, Timeout) ->
    ReplyRef = make_ref(),
    UniqueDatabaseIds = lists:usort(DatabaseIds),
    EmulateLegacyBehaviour = true,
    WaiterOpts = [{emulate_legacy_behaviour, EmulateLegacyBehaviour}],
    Waiters = [{DatabaseId, locus_waiter:start(ReplyRef, DatabaseId, Timeout, WaiterOpts)}
               || DatabaseId <- UniqueDatabaseIds],
    perform_wait(ReplyRef, Waiters, #{}, #{}, EmulateLegacyBehaviour).

%% @doc Returns the currently loaded database version.
%% @deprecated Please use {@link get_info/2} instead.
%%
%% <ul>
%% <li>`DatabaseId' must be an atom and refer to a database loader.</li>
%% </ul>
%%
%% Returns:
%% <ul>
%% <li>`{ok, LoadedVersion}' in case of success</li>
%% <li>`{error, database_unknown}' if the database loader for `DatabaseId' hasn't been started.</li>
%% <li>`{error, database_not_loaded}' if the database hasn't yet been loaded.</li>
%% </ul>
-spec get_version(DatabaseId) -> {ok, LoadedVersion} | {error, Error}
            when DatabaseId :: atom(),
                 LoadedVersion :: database_version(),
                 Error :: database_unknown | database_not_loaded.
get_version(DatabaseId) ->
    get_info(DatabaseId, version).

%% ------------------------------------------------------------------
%% CLI-only Function Definitions
%% ------------------------------------------------------------------

-ifdef(ESCRIPTIZING).
-spec main([string()]) -> no_return().
%% @private
main(Args) ->
    locus_cli:main(Args).
-endif.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

-spec parse_database_edition(database_edition()) -> {maxmind, atom()}.
%% @private
parse_database_edition({maxmind, Atom})
  when is_atom(Atom) ->
    {maxmind, Atom};
parse_database_edition({maxmind, Chardata})
  when ?might_be_chardata(Chardata) ->
    Charlist = unicode:characters_to_list(Chardata),
    Atom = list_to_atom(Charlist),
    {maxmind, Atom};
parse_database_edition(LegacyMaxMindDatabaseEdition)
  when is_atom(LegacyMaxMindDatabaseEdition) ->
    {maxmind, LegacyMaxMindDatabaseEdition}.

-spec parse_url(database_url()) -> locus_database:origin() | false.
parse_url(DatabaseURL) ->
    case parse_http_url(DatabaseURL) of
        Origin when is_tuple(Origin) ->
            Origin;
        false ->
            parse_filesystem_url(DatabaseURL)
    end.

parse_http_url(DatabaseURL) when is_list(DatabaseURL) ->
    try unicode:characters_to_binary(DatabaseURL) of
        <<BinaryChardata/bytes>> ->
            parse_http_url(BinaryChardata);
        _ ->
            false
    catch
        _:_ -> false
    end;
parse_http_url(DatabaseURL) ->
    ByteList = binary_to_list(DatabaseURL),
    try io_lib:printable_latin1_list(ByteList) andalso
        locus_util:parse_absolute_http_url(ByteList)
    of
        false ->
            false;
        {ok, {Scheme, "", "geolite.maxmind.com", Port, "/download/geoip/database/GeoLite2-" ++ Suffix, _, _}}
          when Scheme =:= http, Port =:= 80;
               Scheme =:= https, Port =:= 443 ->
            parse_discontinued_geolite2_http_url(DatabaseURL, Suffix, ByteList);
        {ok, _Result} ->
            {http, ByteList};
        {error, _Reason} ->
            false
    catch
        error:badarg -> false
    end.

parse_discontinued_geolite2_http_url(DatabaseURL, Suffix, ByteList) ->
    case Suffix of
        "Country.tar.gz" ->
            log_warning_on_use_of_discontinued_geolite2_http_url(DatabaseURL, 'GeoLite2-Country'),
            {maxmind, 'GeoLite2-Country'};
        "City.tar.gz" ->
            log_warning_on_use_of_discontinued_geolite2_http_url(DatabaseURL, 'GeoLite2-City'),
            {maxmind, 'GeoLite2-City'};
        "ASN.tar.gz" ->
            log_warning_on_use_of_discontinued_geolite2_http_url(DatabaseURL, 'GeoLite2-ASN'),
            {maxmind, 'GeoLite2-ASN'};
        _ ->
            {http, ByteList}
    end.

log_warning_on_use_of_discontinued_geolite2_http_url(LegacyURL, DatabaseEdition) ->
    locus_logger:log_warning(
      "Public access to GeoLite2 was discontinued on 2019-12-30; converting legacy URL for your convenience.~n"
      "Update your `:start_loader' and `:loader_child_spec' calls to silence this message.~n"
      "(Use the tuple {maxmind, '~ts'} instead of the legacy URL \"~ts\")",
      [DatabaseEdition, LegacyURL]).

parse_filesystem_url(DatabaseURL) ->
    try unicode:characters_to_list(DatabaseURL) of
        Path when is_list(Path) ->
            {filesystem, filename:absname(Path)};
        {error, _Parsed, _RestData} ->
            false;
        {incomplete, _Parsed, _RestData} ->
            false
    catch
        error:badarg -> false
    end.

info_from_db_parts(Parts) ->
    maps:with([metadata, source, version], Parts).

opts_with_defaults(Opts) ->
    [{event_subscriber, locus_logger} | Opts].

perform_wait(_ReplyRef, [], Successes, Failures, EmulateLegacyBehaviour) ->
    case map_size(Failures) =:= 0 of
        true ->
            {ok, Successes};
        false ->
            false = EmulateLegacyBehaviour, % an assertion of self-consistency
            {error, {Failures, Successes}}
    end;
perform_wait(ReplyRef, WaitersLeft, Successes, Failures, EmulateLegacyBehaviour) ->
    case receive_waiter_reply(ReplyRef) of
        {DatabaseId, {ok, Version}} ->
            {value, _, RemainingWaitersLeft} = lists:keytake(DatabaseId, 1, WaitersLeft),
            UpdatedSuccesses = Successes#{ DatabaseId => Version },
            perform_wait(ReplyRef, RemainingWaitersLeft, UpdatedSuccesses, Failures, EmulateLegacyBehaviour);
        {DatabaseId, {error, Reason}}
          when EmulateLegacyBehaviour ->
            {value, _, RemainingWaitersLeft} = lists:keytake(DatabaseId, 1, WaitersLeft),
            stop_waiters(RemainingWaitersLeft),
            flush_waiter_replies(ReplyRef),
            case Reason =:= timeout of
                true  -> {error, timeout};
                false -> {error, {DatabaseId, Reason}}
            end;
        {DatabaseId, {error, Reason}} ->
            {value, _, RemainingWaitersLeft} = lists:keytake(DatabaseId, 1, WaitersLeft),
            UpdatedFailures = Failures#{ DatabaseId => Reason },
            perform_wait(ReplyRef, RemainingWaitersLeft, Successes, UpdatedFailures, EmulateLegacyBehaviour)
    end.

receive_waiter_reply(ReplyRef) ->
    receive
        {ReplyRef, DatabaseId, Reply} ->
            {DatabaseId, Reply}
    end.

flush_waiter_replies(ReplyRef) ->
    receive
        {ReplyRef, _, _} ->
            flush_waiter_replies(ReplyRef)
    after
        0 -> ok
    end.

stop_waiters(Waiters) ->
    lists:foreach(
      fun ({_DatabaseId, WaiterPid}) ->
              WaiterMon = monitor(process, WaiterPid),
              unlink(WaiterPid),
              exit(WaiterPid, normal),
              receive
                  {'DOWN', WaiterMon, _, _, _} ->
                      ok
              after
                  5000 -> % TODO make this concurrent, lest waiting periods accumulate
                      demonitor(WaiterMon, [flush]),
                      exit(WaiterPid, kill)
              end
      end,
      Waiters).
