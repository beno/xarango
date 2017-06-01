
defmodule TransactionTest do
  use ExUnit.Case
  doctest Xarango

  alias Xarango.Transaction
  alias Xarango.Domain.Node
  
  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      Xarango.Collection.__destroy_all()
      try do Xarango.Graph.__destroy_all(_database()) rescue _ -> nil end
      try do Xarango.Collection.__destroy_all(_database()) rescue _ -> nil end
    end
  end
  
  test "execute transaction" do
    result = %Transaction{ collections: %{}, action: "function(){return \"Hello\"}" } |> Transaction.execute
    assert result == "Hello"
  end
  
  test "transaction add" do
    edge = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.create(TransactionTest.Car, %{name: "Foo"}, var: :car1)
      |> Transaction.create(TransactionTest.Car, %{name: "Bar"}, var: :car2)
      |> Transaction.create(TransactionTest.Brand, %{name: "Baz"}, var: :brand)
      |> Transaction.add(:car1, :has_brand, :brand)
      |> Transaction.execute
      |> Xarango.Document.document
    assert String.starts_with?(edge._data[:_from], "transaction_test_car/") 
    assert String.starts_with?(edge._data[:_to], "transaction_test_brand/")
  end
  
  test "transaction add with data" do
    edge = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.create(TransactionTest.Car, %{name: "Foo"}, var: :car1)
      |> Transaction.create(TransactionTest.Car, %{name: "Bar"}, var: :car2)
      |> Transaction.create(TransactionTest.Brand, %{name: "Baz"}, var: :brand)
      |> Transaction.add(:car1, :has_brand, :brand, %{jabba: "dabba"})
      |> Transaction.execute
      |> Xarango.Document.document
    assert match?(%{jabba: "dabba"}, edge._data)
  end

  test "transaction get" do
    result = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.create(TransactionTest.Car, %{name: "Foo"}, var: :car1)
      |> Transaction.create(TransactionTest.Car, %{name: "Bar"}, var: :car2)
      |> Transaction.create(TransactionTest.Brand, %{name: "Baz"}, var: :brand)
      |> Transaction.add(:car1, :has_brand, :brand)
      |> Transaction.add(:car2, :has_brand, :brand)
      |> Transaction.get(TransactionTest.Car, :has_brand, :brand)
      |> Transaction.execute
    assert length(result) == 2
  end
  
  test "transaction update" do
    result = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.create(TransactionTest.Car, %{name: "Foo"}, var: :car1)
      |> Transaction.update(TransactionTest.Car, %{id: :car1, foo: "Bar"})
      |> Transaction.get(:car1, TransactionTest.Car)
      |> Transaction.execute
    assert result[:name] == "Foo"
    assert result[:foo] == "Bar"
  end
  
  test "transaction update node data" do
    car = TransactionTest.Car.create(%{name: "Foo"})
    data = car.vertex._data
      |> Map.put(:id, car[:id])
      |> Map.put(:jabba, "Dabba")
    result = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.update(TransactionTest.Car, data)
      |> Transaction.get(car[:id], TransactionTest.Car)
      |> Transaction.execute
    assert result[:name] == "Foo"
    assert result[:jabba] == "Dabba"
  end

  test "transaction replace node" do
    result = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.create(TransactionTest.Car, %{name: "Foo"}, var: :car1)
      |> Transaction.replace(TransactionTest.Car, %{id: :car1, foo: "Baz"})
      |> Transaction.get(:car1, TransactionTest.Car)
      |> Transaction.execute
    assert result[:name] == nil
    assert result[:foo] == "Baz"
  end

  test "transaction update edge data" do
    car = TransactionTest.Car.create(%{name: "Car"})
    brand = TransactionTest.Brand.create(%{name: "Brand"})
    edge = TransactionTest.TestGraph.add(car, :has_brand, brand, %{foo: "Bar"})
    data = %{id: edge._id, jabba: "Dabba"}
    result = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.update(:has_brand, data)
      |> Transaction.get(edge._id, :has_brand)
      |> Transaction.execute
    assert result._data[:foo] == "Bar"
    assert result._data[:jabba] == "Dabba"
  end

  test "transaction replace edge" do
    car = TransactionTest.Car.create(%{name: "Car"})
    brand = TransactionTest.Brand.create(%{name: "Brand"})
    edge = TransactionTest.TestGraph.add(car, :has_brand, brand, %{foo: "Bar"})
    data = %{id: edge._id, _from: car[:id], _to: brand[:id], jabba: "Dabba"}
    result = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.replace(:has_brand, data)
      |> Transaction.get(edge._id, :has_brand)
      |> Transaction.execute
    assert result._data[:foo] == nil
    assert result._data[:jabba] == "Dabba"
  end

  defp _database do
    %Xarango.Database{name: "test_db"}
  end
  
  defmodule Car, do: use Xarango.Domain.Node, graph: TransactionTest.TestGraph
  defmodule Brand, do: use Xarango.Domain.Node, graph: TransactionTest.TestGraph
  
  defmodule TestGraph do
    use Xarango.Domain.Graph
  
    relationship Car, :has_brand, Brand
  
  end
  
end

