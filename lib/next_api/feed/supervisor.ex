defmodule NextApi.Feed.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    IO.puts "Feed Supervisor"
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def start_feed(supervisor, user_name, session, pid, feed_args) do
    IO.puts "start feed"
    Supervisor.start_child(supervisor, [[user_name, session, pid, feed_args], []])
  end

  def terminate(supervisor, feed_pid) do
    Supervisor.terminate_child(supervisor, feed_pid)
  end

  def init(:ok) do
    children = [
      #worker(NextApi.Feed, [], restart: :temporary)
      worker(NextApi.Feed.Public, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
