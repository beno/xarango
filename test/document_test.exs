defmodule DocumentTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Document
  alias Xarango.Collection
  alias Xarango.Database

  setup do
    on_exit fn ->
      Collection.__destroy_all
    end
  end

  test "create document" do
    collection = Collection.create(collection_)
    document = Document.create(document_, collection)
    assert String.starts_with?(document._id, collection.name <> "/")
  end

  test "read document" do
    source = document_
    collection = Collection.create(collection_)
    document = Document.create(source, collection)
    result = Document.document(document)
    assert result._data == source._data
  end

  
  test "create and retrieve document" do
    collection = Collection.create(collection_)
    document = Document.create(document_, collection, returnNew: true)
    assert String.starts_with?(document._id, collection.name <> "/")
  end
  
  test "create documents" do
    collection = Collection.create(collection_)
    docs = [document_, document_, document_]
    documents = Document.create(docs, collection)
    assert is_list(documents)
    assert length(documents) == 3
  end
  
  test "destroy document" do
    collection = Collection.create(collection_)
    document = Document.create(document_, collection)
    result = Document.destroy(document)
    assert result[:_id] == document._id
  end
  
  test "destroy documents" do
    collection = Collection.create(collection_)
    docs = [document_, document_, document_]
    documents = Document.create(docs, collection)
    result = Document.destroy(documents)
    assert is_list(result)
    assert length(result) == 3
  end
  
  test "replace document" do
    new_data = %{jabba: "dabba"}
    collection = Collection.create(collection_)
    document = Document.create(document_, collection)
    newdoc_ = %Document{document | _data: new_data}
    document = Document.replace(newdoc_)
    document = Document.document(document)
    assert document._data == new_data
  end
  
  test "replace documents" do
    new_data = %{jabba: "dabba"}
    collection = Collection.create(collection_)
    docs = [document_, document_, document_]
    documents = Document.create(docs, collection)
    documents = Enum.map(documents, fn doc -> %Document{doc | _data: new_data} end)
    result = Document.replace(documents)
    assert is_list(result)
    assert length(result) == 3
    document = Document.document(Enum.at(result, 0))
    assert document._data == new_data
  end
  
  test "merge document" do
    source = document_
    new_data = %{jabba: "dabba"}
    collection = Collection.create(collection_)
    document = Document.create(source, collection)
    newdoc_ = %Document{document | _data: new_data}
    document = Document.update(newdoc_, mergeObjects: true)
    document = Document.document(document)
    assert document._data == Map.merge(source._data, new_data)
  end
  
  test "merge documents" do
    new_data = %{jabba: "dabba"}
    collection = Collection.create(collection_)
    docs = [document_]
    documents = Document.create(docs, collection)
    documents = Enum.map(documents, fn doc -> %Document{doc | _data: new_data} end)
    result = Document.update(documents, mergeObjects: true)
    assert is_list(result)
    assert length(result) == 1
    document = Document.document(Enum.at(result, 0))
    assert document._data == Map.merge(Enum.at(docs, 0)._data, new_data)
  end

  test "unknown document" do
    collection = Collection.create(collection_)
    document = %Document{_id: "#{collection.name}/unknown"}
    assert_raise RuntimeError, "document not found", fn ->
      Document.document(document)
    end
  end
  
  test "create document in database" do
    db = Database.create(database_)
    collection = Collection.create(collection_, db)
    document = Document.create(document_, collection, db)
    Database.destroy(db)
    assert String.starts_with?(document._id, collection.name <> "/")
  end


end