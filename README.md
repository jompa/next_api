# Nordnet NextApi

## Description

WIP Wrapper around the [Nordnet nExt API](https://api.test.nordnet.se/). 

Working:
- Rest login
- Public Feed subscription to default values

DO NOT USE THIS APP!

## Use

    iex> NextApi.Users.login "user_name", "password"
    :ok
    iex> NextApi.Users.subscribe_public "user_name", %{type: "price", instrument: 101, market: 30}
    {:ok, "feeding"}
    iex> flush
    {:subscribtion, "{\"type\":\"heartbeat\",\"data\":{}}\n"}

## Installation

Create your account at Nordnet and download the NEXTAPI_TEST_public.pem and put it in the priv folder

  1. Add next_api to your list of dependencies in `mix.exs`:

        def deps do
          [{:next_api, git: "git@github.com:jompa/next_api.git"}]
        end

  2. Ensure next_api is started before your application:

        def application do
          [applications: [:next_api]]
        end
