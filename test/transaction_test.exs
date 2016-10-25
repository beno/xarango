defmodule TransactionTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Transaction
  alias Xarango.Collection
  
  setup do
    on_exit fn ->
      Collection.__destroy_all
    end
  end
  
  test "execute transaction" do
    coll = _collection
    transaction = %Transaction{collections: %{write: [coll.name]}, action: "function(){return \"Hello\"}" }
    result = Transaction.execute(transaction)
    assert result == "Hello"
  end

  defp _collection do
    Collection.create(collection_) |> Collection.collection
  end
  
end
