defmodule QueryTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Query
  alias Xarango.Document

  setup do
    on_exit fn ->
      Xarango.Collection.__destroy_all
    end
  end

  test "query" do
    length = 3
    {coll, _} = _documents(length)
    q = "FOR d IN #{coll.name} RETURN d"
    result = Query.query(q)
    assert result.error == false
    assert length(result.result) == length
  end

  test "next" do
    length = 5
    {coll, _} = _documents(length)
    q = %Query{query: "FOR d IN #{coll.name} RETURN d", batchSize: 3}
    result = Query.query(q)
    assert result.hasMore == true
    assert length(result.result) == 3
    result = Query.next(result)
    assert length(result.result) == 2
  end

  test "explain" do
    {coll, _} = _documents(2)
    q = "FOR d IN #{coll.name} RETURN d"
    explanation = Query.explain(%Query{query: q})
    assert explanation.error == false
  end


  defp _documents(count) do
    coll = Xarango.Collection.create(collection_())
    docs = Enum.map(1..count, fn _ -> Document.create(document_(), coll) end)
    {coll, docs}
  end


end
