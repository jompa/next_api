# Nordnet NextApi

## Description

WIP Wrapper around the [Nordnet nExt API](https://api.test.nordnet.se/). 

Working:
- Rest login
- Public Feed subscription

DO NOT USE THIS APP!

## Use

    iex> NextApi.Users.login "user_name", "password"
    :ok
    iex> NextApi.Users.subscribe_public "user_name", %{type: "price", instrument: "101", market: 11}
    {:ok, "feeding"}
    iex> flush
    {:subscribtion,
        {"user_name",
           %{"data" => %{"ask" => 83.0, "ask_volume" => 10, "bid" => 83.1,
                "bid_volume" => 53080, "close" => 73.1, "high" => 83.1, "i" => "101",
                "last" => 83.1, "last_volume" => 5, "low" => 83.1, "m" => 11,
                "open" => 83.1, "tick_timestamp" => 1461827647858,
                "trade_timestamp" => 1461826978939, "turnover" => 1246.5,
                "turnover_volume" => 15, "vwap" => 83.1}, "type" => "price"}}}

## TODO
- Fix multiple subscriptions on same feed

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
