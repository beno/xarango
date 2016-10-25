defmodule SimpleQueryTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper
  
  alias Xarango.SimpleQuery
  alias Xarango.Document
  
  setup do
    on_exit fn ->
      Xarango.Collection.__destroy_all
    end
  end
  
  test "all" do
    length = 3
    {coll, _} = _documents(length)
    result = SimpleQuery.all(%SimpleQuery{collection: coll.name})
    assert result.error == false
    assert length(result.result) == length
  end
  
  test "by example" do
    {coll, docs} = _documents(3)
    example = Enum.at(docs, 0) |> Document.document |> Map.get(:_data)
    result = SimpleQuery.by_example(%SimpleQuery{collection: coll.name, example: example})
    assert result.error == false
    assert length(result.result) == 1
  end
  
  test "first example" do
    {coll, docs} = _documents(3)
    source = Enum.at(docs, 0) |> Document.document
    doc = SimpleQuery.first_example(%SimpleQuery{collection: coll.name, example: source._data})
    assert doc._data == source._data
  end

  test "find by keys" do
    {coll, docs} = _documents(3)
    source1 = Enum.at(docs, 0) |> Document.document
    source2 = Enum.at(docs, 1) |> Document.document
    docs = SimpleQuery.find_by_keys(%SimpleQuery{collection: coll.name, keys: [source1._key, source2._key]})
    assert length(docs) == 2
  end
  
  test "random" do
    {coll, docs} = _documents(1)
    source = Enum.at(docs, 0) |> Document.document
    doc = SimpleQuery.random(%SimpleQuery{collection: coll.name})
    assert source == doc
  end
  
  test "destroy by keys" do
    {coll, docs} = _documents(3)
    source1 = Enum.at(docs, 0) |> Document.document
    source2 = Enum.at(docs, 1) |> Document.document
    result = SimpleQuery.destroy_by_keys(%SimpleQuery{collection: coll.name, keys: [source1._key, source2._key], options: %{waitForSync: true}})
    assert result[:error] == false
    assert result[:removed] == 2
  end
  
  test "destroy by example" do
    {coll, docs} = _documents(3)
    example = Enum.at(docs, 0) |> Document.document
    query = %SimpleQuery{collection: coll.name, example: example._data, options: %{waitForSync: true}}
    result = SimpleQuery.destroy_by_example(query)
    assert result[:error] == false
    assert result[:deleted] == 1
  end

  test "replace by example" do
    {coll, docs} = _documents(3)
    example = Enum.at(docs, 0) |> Document.document
    new_value = %{foo: "bar"}
    query = %SimpleQuery{collection: coll.name, example: example._data, newValue: new_value, options: %{waitForSync: true}}
    result = SimpleQuery.replace_by_example(query)
    assert result[:error] == false
    assert result[:replaced] == 1
    assert Document.document(example)._data == new_value
  end

  test "update by example" do
    {coll, docs} = _documents(3)
    example = Enum.at(docs, 0) |> Document.document
    new_value = %{foo: "bar"}
    query = %SimpleQuery{collection: coll.name, example: example._data, newValue: new_value, options: %{waitForSync: true}}
    result = SimpleQuery.update_by_example(query)
    assert result[:error] == false
    assert result[:updated] == 1
    assert Document.document(example)._data == Map.merge(example._data, new_value)
  end
  
  test "range" do
    {coll, _} = _documents(10)
    query = %SimpleQuery{collection: coll.name, left: "a", right: "h", attribute: "field", skip: 0, limit: 100}
    result = SimpleQuery.range(query)
    assert is_list(result)
    assert length(result) > 0
  end
  
  test "near" do
    coll = Xarango.Collection.create(collection_)
    index = %Xarango.Index{type: "geo", fields: ["lat", "lon"], geoJson: true}
      |> Xarango.Index.create(coll)
    _geo_documents(10, coll)
    query = %SimpleQuery{collection: coll.name, latitude: Faker.Address.latitude, longitude: Faker.Address.longitude, limit: 100}
    result = SimpleQuery.near(query)
    Xarango.Index.destroy(index)
    assert is_list(result)
    assert length(result) > 0
  end
  
  test "within" do
    coll = Xarango.Collection.create(collection_)
    index = %Xarango.Index{type: "geo", fields: ["lat", "lon"], geoJson: true}
      |> Xarango.Index.create(coll)
    _geo1_documents(10, coll)
    query = %SimpleQuery{collection: coll.name, latitude: 0, longitude: 0, radius: 1000, attribute: "distance", skip: 0 }
    result = SimpleQuery.within(query)
    Xarango.Index.destroy(index)
    assert is_list(result)
    assert length(result) > 0
  end

  test "within rectangle" do
    coll = Xarango.Collection.create(collection_)
    index = %Xarango.Index{type: "geo", fields: ["lat", "lon"], geoJson: true}
      |> Xarango.Index.create(coll)
    _geo1_documents(10, coll)
    query = %SimpleQuery{collection: coll.name, latitude1: 0, longitude1: 0, latitude2: 1, longitude2: 1, skip: 0, limit: 100}
    result = SimpleQuery.within_rectangle(query)
    Xarango.Index.destroy(index)
    assert is_list(result)
    assert length(result) > 0
  end

  defp _documents(count) do
    coll = Xarango.Collection.create(collection_)
    docs = Enum.map(1..count, fn _ -> Document.create(document_, coll) end)
    {coll, docs}
  end
  
  defp _geo_documents(count, coll) do
    Enum.map(1..count, fn _ -> 
      %Document{ document_ | _data: %{lat: Faker.Address.latitude, lon: Faker.Address.longitude} }
      |> Document.create(coll) 
    end)
  end
  
  defp _geo1_documents(count, coll) do
    Enum.map(1..count, fn _ -> 
      %Document{ document_ | _data: %{lat: _num, lon: _num} }
      |> Document.create(coll) 
    end)
  end
  
  defp _num() do
    String.to_integer(Faker.Phone.EnUs.extension)/1000000
  end

  
    
end