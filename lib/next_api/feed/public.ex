defmodule NextApi.Feed.Public do
  use GenServer

  @initial_state %{controlling_pid: nil, session: nil, socket: nil}

  def start_link([session, pid, feed_args], opts \\ []) do
    IO.puts "start_link"
    IO.inspect pid
    GenServer.start_link(__MODULE__, {session, pid, feed_args, @initial_state}, opts)
  end

  def init({session, pid, _feed_args, state}) do
    state = %{state | session: session, controlling_pid: pid}
    IO.puts "init feed"
    case open_socket(state) do
      {:ok, socket} ->
        :ssl.setopts(socket, active: :once)
        {:ok, subscribe} = Poison.encode %{cmd: "subscribe", args: %{t: "price", i: 1869, m: 30}}
        case :ssl.send(socket, subscribe) do
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
    send state.controlling_pid, {:subscribtion, msg}
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
      %{"session_key" => session_key, "public_feed" => public_feed } = state.session

      opts = [:binary, active: false, packet: :line]

      {:ok, socket} = :ssl.connect(to_char_list(public_feed["hostname"]), public_feed["port"], opts)
      :ok = :ssl.ssl_accept(socket)

      ## format login call
      {:ok, login} = Poison.encode %{cmd: "login", args: %{session_key: session_key, service: "NEXTAPI"}}

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
