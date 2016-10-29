# Xarango

Elixir client library for ArangoDB.

## Usage

Configure xarango in `config/confix.exs`:

    config :xarango, db: [
      server: "http://localhost:8529",
      database: "test_db",
      version: 30000,
      username: System.get_env("ARANGO_USER"),
      password: System.get_env("ARANGO_PASSWORD")
    ]

Set your credentials:

    $ export ARANGO_USER=root
    $ export ARANGO_PASSWORD=secret

Run tests:

    mix test # <= beware: running tests will destroy all data in the configured database.
    
See tests for usage examples.

## Installation

The package can be installed as:

  1. Add `xarango` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:xarango, "~> 0.2.0"}]
    end
    ```

  2. Ensure `xarango` is started before your application:

    ```elixir
    def application do
      [applications: [:xarango]]
    end
    ```

