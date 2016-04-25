defmodule NextApi.Rest do

  @next_base_url "https://api.test.nordnet.se"
  @next_version 2

  @moduledoc """
  Module handling rest calls
  """

  @doc """
  Does the login request

  Returns a the json result as a map
  """
  #@spec login(binary, binary) :: Map.t
  def login(user, pass) do

    {:ok, pem} = File.read("./priv/NEXTAPI_TEST_public.pem")

    [pem_entry] = :public_key.pem_decode(pem)
    rsa_pub_key = :public_key.pem_entry_decode(pem_entry)

    timestamp = Integer.to_string(:erlang.system_time :milli_seconds)

    buf = Base.encode64(user) <> ":" <> Base.encode64(pass) <> ":" <> Base.encode64(timestamp)
    encrypted_hash = Base.encode64(:public_key.encrypt_public(buf, rsa_pub_key))

    url = create_url("login")
    params = [{:service,"NEXTAPI"},
      {:auth, encrypted_hash}
    ]
    headers = create_headers
    options = [{:params, params}]

    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.post(url, "", headers, options)

    case Poison.Parser.parse! body do
      %{"code" => "NEXT_LOGIN_INVALID_LOGIN_PARAMETER", "message" => msg} ->
        {:error, msg}
      session ->
        {:ok, session}
    end
  end

  #def logout(session_key) do
  #end

  @doc """
  Takes a session map and returns all accounts
  """
  def get_accounts(%{"session_key" => session_key}) do
    headers = create_headers(session_key)
    url = create_url("accounts")

    {:ok, %HTTPoison.Response{body: body}} = HTTPoison.get(url, headers)

    Poison.Parser.parse! body
  end

  defp create_headers(session_key) do
    auth = session_key <> ":" <> session_key
    |> Base.encode64

    [{"Authorization", "Basic " <> auth} | create_headers]
  end

  defp create_headers() do
    [{"Accept", "application/json"}]
  end

  defp create_url(endpoint) do
    @next_base_url <> "/next/" <> Integer.to_string(@next_version) <> "/" <> endpoint
  end
  
end
