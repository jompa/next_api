defmodule NextApi.Users do
  use GenServer

  @initial_state %{users: %{}, feed_supervisor: nil}

  def start_link(feed_supervisor, opts \\ []) do
    GenServer.start_link(__MODULE__, {feed_supervisor, @initial_state}, opts)
  end

  def init({feed_supervisor, state}) do
    state = %{state | feed_supervisor: feed_supervisor}
    IO.puts "Starting User Registry"
    :ssl.start()
    {:ok, state}
  end

  # Public
  def login(user, pass) do
    GenServer.call(__MODULE__, {:login, user, pass})
  end

  def logout() do
    GenServer.call(__MODULE__, :logout)
  end

  def subscribe_public() do
    GenServer.call(__MODULE__, :subscribe_public)
  end

  # Private
  def handle_call({:login, user, pass}, {pid, _ref}, state) do
    case NextApi.Rest.login user, pass do
      {:ok, session} ->
        user = %NextApi.User{session: session}
        state = %{state | users: Map.put(state.users, pid, user)}
        {:reply, :ok, state}
      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call(:logout, {pid, _ref}, state) do

    case state.users do
      %{^pid => %NextApi.User{session: _session, feed: nil}} ->
        # remove user
        {_, users} = Map.pop(state.users, pid)
        state = %{state | users: users}
        {:reply, {:error, "aye it's done"}, state}

      %{^pid => %NextApi.User{session: _session, feed: feed}} ->
        # remove user
        {_, users} = Map.pop(state.users, pid)
        state = %{state | users: users}
        # terminate feed
        NextApi.Feed.Supervisor.terminate state.feed_supervisor, feed
        {:reply, {:ok, "you are logged out"}, state}

      _ ->
        {:reply, {:error, "you are not logged in"}, state}
    end
  end

  def handle_call(:subscribe_public, {pid, _ref}, state) do

    # find user in state
    case state.users do
      %{^pid => %NextApi.User{session: session, feed: nil}} ->
        # user found but no feed
        case  NextApi.Feed.Supervisor.start_feed state.feed_supervisor, session, pid, %{} do
          {:ok, feed} ->
            user = %NextApi.User{session: session, feed: feed}
            state = %{state | users: Map.put(state.users, pid, user)}
            {:reply, {:ok, "feeding"}, state}
            #case NextApi.Feed.subscribe_public feed do
              #{:ok, msg} ->
                #{:reply, {:ok, msg}, state}
              #{:error, msg} ->
                #{:reply, {:error, msg}, state}
            #end
          {:error, reason} ->
            {:reply, {:error, "error starting feed #{reason}"}, state}
        end

      %{^pid => %NextApi.User{session: _session, feed: _feed}} ->
        {:reply, {:error, "you already have a feed"}, state}

      _ ->
        {:reply, {:error, "You must login to get a session"}, state}
    end
  end
end
