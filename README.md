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
ipsum = Article.create(%{author: "Author", text: "Lorem"})

IO.inspect lorem[:text] #=> "Lorem"

Article.list(%{author: "Author"}) #=> [%Article{...}, %Article{...}]

Article.update(ipsum, %{status: "review"})

Article.destroy(ipsum)

```


## Example Graph

```elixir
defmodule Brand, do: use Xarango.Domain.Vertex
defmodule Car, do: use Xarango.Domain.Vertex, graph: :vehicles
defmodule Vehicles do
  use Xarango.Domain.Graph
  
  relationship :car, :has_brand, :brand
end

Vehicles.create
subaru = Brand.create(%{name: "Subaru"}, :vehicles)
outback = Car.create(%{type: "Outback"})
impreza = Car.create(%{type: "Impreza"})

IO.inspect subaru[:name] #=> "Subaru"
IO.inspect outback[:type] #=> "Outback"

Vehicles.add_has_brand(outback, subaru)
Vehicles.add_has_brand(impreza, subaru)

Vehicles.car_has_brand(subaru) #=> [%Car{...}, %Car{...}] #outbound edges for car
Vehicles.has_brand_brand(outback) #=> [%Brand{...}] #inbound edges for brand

Vehicles.remove_has_brand(impreza, subaru)

Vehicles.car_has_brand(subaru) #=> [%Car{...}]


```

See tests for low level usage examples.

## Installation

The package can be installed as:

  1. Add `xarango` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:xarango, "~> 0.2.1"}]
    end
    ```

  2. Ensure `xarango` is started before your application:

    ```elixir
    def application do
      [applications: [:xarango]]
    end
    ```

