defmodule CollectionTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Collection

  setup do
    on_exit fn ->
      Xarango.Collection.__destroy_all
    end
  end

  test "list collections" do
    list = Collection.collections()
    assert is_list(list)
    assert length(list) > 0
  end

  test "create collection" do
    source = collection_()
    collection = Collection.create(source)
    assert collection.name == source.name
  end

  test "destroy collection" do
    collection = Collection.create(collection_())
    response = Collection.destroy(collection)
    assert response[:error] == false
  end

  test "retrieve collection" do
    source = collection_()
    collection = Collection.create(source)
    collection = Collection.collection(collection)
    assert collection.name == source.name
  end

  test "get document count" do
    source = collection_()
    collection = Collection.create(source)
    collection = Collection.count(collection)
    assert collection.count == 0
  end

  test "get collection properties" do
    collection = Collection.create(collection_())
    collection = Collection.properties(collection)
    assert collection.journalSize > 0
  end

  test "get collection figures" do
    collection = Collection.create(collection_())
    collection = Collection.figures(collection)
    assert Enum.any?(collection.figures)
  end

  test "get collection revision" do
    collection = Collection.create(collection_())
    collection = Collection.revision(collection)
    assert collection.revision == "0"
  end

  test "get collection checksum" do
    collection = Collection.create(collection_())
    collection = Collection.checksum(collection)
    assert collection.checksum == "0"
  end


end
