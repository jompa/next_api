defmodule NextApi.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @users_name NextApi.Users
  @feed_sup_name NextApi.Feed.Supervisor

  def init(:ok) do
    children = [
      supervisor(NextApi.Feed.Supervisor, [[name: @feed_sup_name]]),
      worker(NextApi.Users , [@feed_sup_name, [name: @users_name]])
    ]

     supervise(children, strategy: :one_for_one)
  end
end
