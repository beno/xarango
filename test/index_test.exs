defmodule IndexTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Index
  alias Xarango.Collection

  setup do
    on_exit fn ->
      Collection.__destroy_all
    end
  end

  test "hash index" do
    coll = _collection()
    index = %Index{type: "hash", fields: ["field"]}
      |> Index.create(coll)
    refute index.error
    assert index.type == "hash"
    assert index.fields == ["field"]
  end

  test "geo index loc" do
    coll = _collection()
    index = %Index{type: "geo", fields: ["location"], geoJson: true}
      |> Index.create(coll)
    refute index.error
    assert index.type == "geo1"
    assert index.fields == ["location"]
  end

  test "geo index lat/lon" do
    coll = _collection()
    index = %Index{type: "geo", fields: ["lat", "lon"], geoJson: true}
      |> Index.create(coll)
    refute index.error
    assert index.type == "geo2"
    assert index.fields == ["lat", "lon"]
  end


  test "destroy index" do
    coll = _collection()
    index = %Index{type: "hash", fields: ["field"]}
      |> Index.create(coll)
    result = Index.destroy(index)
    refute result[:error]
    assert result[:id] == index.id
  end



  defp _collection do
    Collection.create(collection_()) |> Collection.collection
  end

end
