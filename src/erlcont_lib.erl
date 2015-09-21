%%%-------------------------------------------------------------------
%%% @author skell
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. Sep 2015 4:50 PM
%%%-------------------------------------------------------------------
-module(erlcont_lib).
-author("skell").

%% API
-export([find_erl/1]).
-include_lib("kernel/include/file.hrl").

%% Find all files ending in .erl
find_erl(Directory) ->
  find_erl(Directory, queue:new()).

%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Internal implementation of the find_erl function.
%%
%% @end
%%--------------------------------------------------------------------
find_erl(Name, Queue) ->
  {ok, F=#file_info{}} = file:read_file_info(Name),
  case F#file_info.type of
    directory -> handle_directory(Name, Queue);
    regular -> handle_regular_file(Name, Queue);
    _Other -> dequeue_and_run(Queue)
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handles directory files.
%%
%% @end
%%--------------------------------------------------------------------
handle_directory(Dir, Queue) ->
  case file:list_dir(Dir) of
    {ok, []} ->
      dequeue_and_run(Queue);
    {ok, Files} ->
      dequeue_and_run(enqueue_many(Dir, Files, Queue))
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handles files.
%%
%% @end
%%--------------------------------------------------------------------
handle_regular_file(Name, Queue) ->
  case filename:extension(Name) of
    ".erl" ->
      {continue, Name, fun() -> dequeue_and_run(Queue) end};
    _NonErl ->
      dequeue_and_run(Queue)
  end.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Pops an item of the queue and runs it.
%%
%% @end
%%--------------------------------------------------------------------
dequeue_and_run(Queue) ->
  case queue:out(Queue) of
    {empty, _} -> done;
    {{value, File}, NewQueue} -> find_erl(File, NewQueue)
  end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Enqueus the files found in a directory.
%%
%% @end
%%--------------------------------------------------------------------
enqueue_many(Path, Files, Queue) ->
  F = fun(File, Q) -> queue:in(filename:join(Path,File), Q) end,
  lists:foldl(F, Queue, Files).