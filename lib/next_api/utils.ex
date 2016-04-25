defmodule NextApi.Utils do
  def get_env_var(key) do
    case Application.get_env(:nn_next, key) do
      nil ->
        IO.puts "Make sure to set the #{key} environment varible"
      var ->
        var
    end
  end
end
