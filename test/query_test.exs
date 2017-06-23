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

  test "query builder" do
    coll = %{name: "products"}
    q = Query.from(coll)
    |> Query.where([foo: "bar", size: 4])
    |> Query.where(%{age: 10})
    |> Query.limit(4)
    |> Query.paginate(20)
    assert Xarango.AQL.to_aql(q.query) == "FOR x IN products FILTER x.foo == 'bar' FILTER x.size == 4 FILTER x.age == 10 LIMIT 4 RETURN x"
    assert q.batchSize == 20
    assert q.count == true
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

  test "fulltext" do
    collection = %{name: "things"}
    q = Query.from(collection)
    |> Query.search("field", "value")
    |> Query.paginate(10)
    assert Xarango.AQL.to_aql(q.query) == "FOR x IN FULLTEXT(things, 'field', 'prefix:value') RETURN x"
    assert q.batchSize == 10
  end

  test "build" do
    collection = %{name: "things"}
    filter = [name: "foo"]
    options = [per_page: 20, sort: :name]
    q = Query.build(collection, filter, options)
    assert Xarango.AQL.to_aql(q.query) == "FOR x IN things FILTER x.name == 'foo' SORT x.name ASC RETURN x"
    assert q.batchSize == 20
  end

  defp _documents(count) do
    coll = Xarango.Collection.create(collection_())
    docs = Enum.map(1..count, fn _ -> Document.create(document_(), coll) end)
    {coll, docs}
  end


end
