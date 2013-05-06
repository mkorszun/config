-module(config).
-author('mkorszun@gmail.com').

-export([get_env/3, get_env/4]).

-type type() :: [integer | string | binary].
-type key() :: [atom() | list() | binary()].
-type value() :: [integer() | list() | binary()].

%% ###############################################################
%% API
%% ###############################################################

-spec get_env(atom(), key(), type()) -> value() | undefined.
get_env(Application, Key, Type) ->
    get_env(Application, Key, Type, undefined).

-spec get_env(atom(), key(), type(), value()) -> value() | undefined.
get_env(Application, Key, Type, Default) ->
    case get_env(Application, Key) of
        undefined ->
            format(Default, Type);
        Val ->
            format(Val, Type)
    end.

%% ###############################################################
%% INTERNAL FUNCTIONS
%% ###############################################################

get_env(Application, Key) ->
    Res = lists:foldl(fun(Source, Acc) ->
        case Source(Application, Key) of
            undefined ->
                Acc;
            Val ->
                dict:store(Key, Val, Acc)
        end
    end, dict:new(), sources()),
    try dict:fetch(Key, Res) of
        Val -> Val
    catch _:_
        -> undefined
    end.

sources() ->
    [fun cfg_env/2, fun os_env/2].

cfg_env(Application, Key) ->
    case application:get_env(Application, Key) of
        {ok, Val} ->
            Val;
        undefined ->
            undefined
    end.

os_env(_Application, Key) ->
    case os:getenv(key(Key)) of
        false ->
            undefined;
        Val ->
            Val
    end.

key(K) when is_atom(K) ->
    key(atom_to_list(K));
key(K) when is_list(K) ->
    string:to_upper(K);
key(K) when is_binary(K) ->
    key(binary_to_list(K)).

format(undefined, _) -> undefined;
format(Val, integer) when is_integer(Val) -> Val;
format(Val, integer) when is_list(Val) -> list_to_integer(Val);
format(Val, integer) when is_binary(Val) -> list_to_integer(binary_to_list(Val));
format(_, integer) -> throw(bad_format);

format(Val, string) when is_list(Val) -> Val;
format(Val, string) when is_integer(Val) -> integer_to_list(Val);
format(Val, string) when is_binary(Val) -> binary_to_list(Val);
format(_, string) -> throw(bad_format);

format(Val, binary) when is_binary(Val) -> Val;
format(Val, binary) when is_integer(Val) -> integer_to_list(list_to_binary(Val));
format(Val, binary) when is_list(Val) -> list_to_binary(Val).

%% ###############################################################
%% TESTS
%% ###############################################################

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

get_env_cfg_test() ->
    application:set_env(app, "Par", "65"),
    ?assertEqual("65", config:get_env(app, "Par", string)),
    ?assertEqual(65, config:get_env(app, "Par", integer)),
    ?assertEqual(<<"65">>, config:get_env(app, "Par", binary)).

get_env_os_test() ->
    os:putenv("LKJKLJKLJLKJLKJK", "9999"),
    ?assertEqual(9999, config:get_env(app, "LKJKLJKLJLKJLKJK", integer)),
    ?assertEqual("9999", config:get_env(app, "LKJKLJKLJLKJLKJK", string)),
    ?assertEqual(<<"9999">>, config:get_env(app, "LKJKLJKLJLKJLKJK", binary)).

get_env_default_test() ->
    ?assertEqual(undefined, config:get_env(app, "par1", integer)),
    ?assertEqual(1111, config:get_env(app, "par1", integer, 1111)).

get_env_os_overwrite_cfg_test() ->
    application:set_env(app, par1, 65),
    os:putenv("PAR1", "66"),
    ?assertEqual(66, config:get_env(app, "par1", integer)).

-endif.

%% ###############################################################
%% ###############################################################
%% ###############################################################