# Xarango

Elixir client library for [ArangoDB](https://www.arangodb.com).

Xarango has a low level API that maps directly to the Arango REST API. On top of that sits a `Domain` API, intended for use in applications. Examples below.


## Usage

Configure xarango in `config/config.exs`:

```elixir
    config :xarango, :db,
      server: "http://localhost:8529",
      database: "test_db",
      username: System.get_env("ARANGO_USER"),
      password: System.get_env("ARANGO_PASSWORD")
```

Set your credentials:

    $ export ARANGO_USER=root
    $ export ARANGO_PASSWORD=secret

Run tests:

    mix test # <= beware: running tests will destroy all data in the configured database.

## Documents

```elixir
defmodule Article, do: use Xarango.Domain.Document

lorem = Article.create(%{author: "Author", text: "Lorem"})
ipsum = Article.create(%{author: "Author", text: "Ipsum"})

IO.inspect lorem[:text] #=> "Lorem"


Article.one(%{author: "Author"}) #=> %Article{...}
Article.list(%{author: "Author"}) #=> %Xarango.QueryResult{result: [%Article{...}, %Article{...}]}
Article.list(%{}, [sort: :author, per_page: 10] #=> serial pagination with cursor (fast)
Article.list(%{}, [sort: :author, dir: :desc, per_page: 10, page: 1] #=> pagination with page nrs (skip, limit)

Article.search(:text, "ips"}) #=> [%Article{..}]

Article.update(ipsum, %{status: "review"})
Article.replace(lorem, %{author: "Author", text: "Foo"})

Article.destroy(ipsum)

```


## Graphs

```elixir
defmodule Brand, do: use Xarango.Domain.Node
defmodule Car, do: use Xarango.Domain.Node, graph: Vehicles, collection: :all_cars
defmodule Vehicles do
  use Xarango.Domain.Graph

  relationship Car, :made_by, Brand
end

subaru = Brand.create(%{name: "Subaru"}, graph: Vehicles)
outback = Car.create(%{type: "Outback"})
impreza = Car.create(%{type: "Impreza"})

subaru[:name] #=> "Subaru"
outback[:type] #=> "Outback"

Vehicles.add_made_by(outback, subaru)
Vehicles.add(impreza, :made_by, subaru)

Vehicles.car_made_by(subaru) #=> [%Car{...}, %Car{...}] #outbound edges for car
Vehicles.get(Car, :made_by, subaru) #=> [%Car{...}, %Car{...}]

Vehicles.made_by_brand(outback) #=> [%Brand{...}]
Vehicles.get(outback, :made_by, Brand) #=> [%Brand{...}

Vehicles.remove_made_by(impreza, subaru)
Vehicles.remove(outback, :made_by, subaru)

Car.search(:name, "imp") #=> [%Car{...}]


```

## Transactions

```elixir
defmodule Brand, do: use Xarango.Domain.Node, graph: Vehicles
defmodule Car, do: use Xarango.Domain.Node, graph: Vehicles
defmodule Vehicles do
  use Xarango.Domain.Graph

  relationship Car, :made_by, Brand
end

alias Xarango.Transaction

Transaction.begin(Vehicles)
|> Transaction.create(Car, %{name: "Foo"}, var: :car1)
|> Transaction.create(Car, %{name: "Bar"}, var: :car2)
|> Transaction.create(Brand, %{name: "Baz"}, var: :brand)
|> Transaction.add(:car1, :made_by, :brand)
|> Transaction.add(:car2, :made_by, :brand)
|> Transaction.get(Car, :made_by, :brand)
|> Transaction.execute #=> [%Car{vertex: ...}, %Car{vertex: ...}]
```

## Low level API

See tests for low level usage examples.

## Todo

- [x] Transactions
- [x] Graph operations
- [x] Full text search
- [x] AQL support, query builder
- [ ] waitForSync option

## Installation

The package can be installed as:

  1. Add `xarango` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:xarango, "~> 0.5.7"}]
    end
    ```

  2. Ensure `xarango` is started before your application:

    ```elixir
    def application do
      [applications: [:xarango]]
    end
    ```
