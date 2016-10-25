# Xarango

Elixir client library for ArangoDB.

## Usage

Export username and password for your db user account:

    export ARANGO_USER=root
    export ARANGO_PASSWORD=foobar
    
Run tests

    mix test
    
See tests for usage examples.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `xarango` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:xarango, "~> 0.1.0"}]
    end
    ```

  2. Ensure `xarango` is started before your application:

    ```elixir
    def application do
      [applications: [:xarango]]
    end
    ```

