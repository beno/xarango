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
    
## Example Document

```elixir
defmodule Article, do: use Xarango.Domain.Document

lorem = Article.create(%{author: "Author", text: "Lorem"})
ipsum = Article.create(%{author: "Author", text: "Ipsum"})

IO.inspect lorem[:text] #=> "Lorem"

Article.one(%{author: "Author"}) #=> %Article{...}
Article.list(%{author: "Author"}) #=> [%Article{...}, %Article{...}]

Article.update(ipsum, %{status: "review"})
Article.replace(lorem, %{author: "Author", text: "FooBar"})

Article.destroy(ipsum)

```


## Example Graph

```elixir
defmodule Brand, do: use Xarango.Domain.Node
defmodule Car, do: use Xarango.Domain.Node, graph: :vehicles
defmodule Vehicles do
  use Xarango.Domain.Graph
  
  relationship Car, :made_by, Brand
end

Vehicles.create
subaru = Brand.create(%{name: "Subaru"}, :vehicles)
outback = Car.create(%{type: "Outback"})
impreza = Car.create(%{type: "Impreza"})

subaru[:name] #=> "Subaru"
outback[:type] #=> "Outback"

Vehicles.add_made_by(outback, subaru)
Vehicles.add_made_by(impreza, subaru)

Vehicles.car_made_by(subaru) #=> [%Car{...}, %Car{...}] #outbound edges for car
Vehicles.made_by_brand(outback) #=> [%Brand{...}] #inbound edges for car

Vehicles.remove_made_by(impreza, subaru)

Vehicles.car_made_by(subaru) #=> [%Car{...}]


```

See tests for low level usage examples.

## Installation

The package can be installed as:

  1. Add `xarango` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:xarango, "~> 0.3.0"}]
    end
    ```

  2. Ensure `xarango` is started before your application:

    ```elixir
    def application do
      [applications: [:xarango]]
    end
    ```

