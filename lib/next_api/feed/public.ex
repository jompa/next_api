defmodule NextApi.Feed.Public do
  use GenServer

  @initial_state %{user_name: nil, session_key: nil, public_feed: nil, type: nil, instrument: nil, market: nil, controlling_pid: nil, socket: nil}

  def start_link([user_name, session, pid, params], opts \\ []) do
    IO.puts "start_link"
    IO.inspect pid
    GenServer.start_link(__MODULE__, {user_name, session, pid, params, @initial_state}, opts)
  end

  def init({user_name, %{"session_key" => session_key, "public_feed" => public_feed}, pid, params, state}) do
    %{type: type, instrument: instrument, market: market} = params

    state = %{state |
      user_name: user_name,
      session_key: session_key,
      public_feed: public_feed,
      controlling_pid: pid,
      type: type,
      instrument: instrument,
      market: market
    }

    IO.puts "init feed with type:#{type}, market:#{market}, instrument:#{instrument}"

    case open_socket(state) do
      {:ok, socket} ->
        :ssl.setopts(socket, active: :once)
        {:ok, subscribe} = Poison.encode %{cmd: "subscribe", args: %{t: type, i: instrument, m: market}}
        IO.inspect subscribe
        case :ssl.send(socket, subscribe <> "\n") do
          :ok ->
            state = %{state | socket: socket}
            {:ok, state}
          {:error, reason} ->
            {:stop, "ssl error #{reason}"}
        end

      {:error, reason} ->
        {:stop, "login error #{reason}"}
    end
  end

  def handle_info({:ssl, socket, msg}, state) do
    # Get client event manager
    :ssl.setopts(socket, active: :once)
    send state.controlling_pid, {:subscribtion, {state.user_name, Poison.decode! msg}}
    {:noreply, state}
  end

  def handle_info({:ssl_closed, _socket}, state) do
    send state.controlling_pid, {:error, "ssl closed"}
    {:stop, state}
  end

  def terminate(_reason, state) do
    # Close socket
    :ok = :ssl.close(state.socket)
    # Remove socket from state
    #state = %{state | socket: nil}
    #{:reply, {:ok, "closed"}, state}
  end

  # helpers
  defp open_socket(state) do
    unless is_port(state.socket) do

      opts = [:binary, active: false, packet: :line]

      {:ok, socket} = :ssl.connect(to_char_list(state.public_feed["hostname"]), state.public_feed["port"], opts)
      :ok = :ssl.ssl_accept(socket)

      ## format login call
      {:ok, login} = Poison.encode %{cmd: "login", args: %{session_key: state.session_key, service: "NEXTAPI"}}

      case :ssl.send(socket, login <> "\n") do
        :ok ->
          {:ok, socket}
        {:error, reason} ->
          :ssl.close(socket)
          {:error, reason}
      end
    else
      {:ok, state.socket}
    end
  end
end
