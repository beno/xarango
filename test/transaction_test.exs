defmodule TransactionTest do
  use ExUnit.Case
  doctest Xarango

  alias Xarango.Transaction
  
  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      Xarango.Collection.__destroy_all()
      try do Xarango.Graph.__destroy_all(_database) rescue _ -> nil end
      try do Xarango.Collection.__destroy_all(_database) rescue _ -> nil end
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
      |> Xarango.Edge.edge
    assert String.starts_with?(edge._from, "transaction_test_car/") 
    assert String.starts_with?(edge._to, "transaction_test_brand/")
  end
  
  test "transaction add with data" do
    edge = Transaction.begin(TransactionTest.TestGraph)
      |> Transaction.create(TransactionTest.Car, %{name: "Foo"}, var: :car1)
      |> Transaction.create(TransactionTest.Car, %{name: "Bar"}, var: :car2)
      |> Transaction.create(TransactionTest.Brand, %{name: "Baz"}, var: :brand)
      |> Transaction.add(:car1, :has_brand, :brand, %{jabba: "dabba"})
      |> Transaction.execute
      |> Xarango.Edge.edge
    assert edge._data == %{jabba: "dabba"}
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

