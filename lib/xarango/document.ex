defmodule Xarango.Document do
  
  defstruct [:_key, :_id, :_rev, :_oldRev, :_data]
  
  alias Xarango.Client
  alias Xarango.Document
  
  def document(document) do
    url(document._id)
    |> Client.get
    |> to_document
  end
  
  def documents(collection) do
    %Xarango.SimpleQuery{collection: collection.name}
    |> Xarango.SimpleQuery.all
    |> Map.get(:result)
    |> Enum.map(&struct(Document, &1))
  end

  def create(document, collection) do
    create(document, collection, nil, [])
  end

  def create(document, collection, options) when is_list(options) do
    create(document, collection, nil, options)
  end
  
  def create(document, collection, database) when is_map(database) do
    create(document, collection, database, [])
  end

  
  # def create(document, collection, database\\nil, options\\[])


  def create(documents, collection, database, options) when is_list(documents) do
    data = Enum.map(documents, &Map.get(&1, :_data))
    url(collection.name, database, options)
    |> Client.post(data)
    |> Enum.map(&struct(Document, &1))
  end

  def create(document, collection, database, options) do
    url(collection.name, database, options)
    |> Client.post(document._data)
    |> case do
      %{new: new_doc} -> new_doc
      doc -> doc
    end
    |> to_document
  end

  def destroy(document, options\\[])
    
  def destroy(documents, options) when is_list(documents) do
    documents
    |> ids_per_collection
    |> Enum.reduce([], fn {coll_name, ids}, acc -> 
      url(coll_name, options)
      |> Client.delete(ids)
      |> Kernel.++(acc)
    end)
  end

  def destroy(document, options) do
    url(document._id, options)
    |> Client.delete
  end
  
  def __destroy_all do
    Xarango.Collection.collections
    |> Enum.reject(&Map.get(&1, :isSystem))
    |> Enum.map(&documents(&1))
    |> Enum.each(&destroy(&1))
  end
  
  def update(documents, options\\[])
  
  def update(documents, options) when is_list(documents) do
    documents
    |> docs_per_collection
    |> Enum.reduce([], fn {coll_name, docs}, acc -> 
      url(coll_name, options)
      |> Client.patch(docs)
      |> Kernel.++(acc)
    end)
  end
  
  def update(document, options) do
    url(document._id, options)
    |> Client.patch(document._data)
    |> to_document
  end
  
  def replace(documents, options\\[])

  def replace(documents, options) when is_list(documents) do
    documents
    |> docs_per_collection
    |> Enum.reduce([], fn {coll_name, docs}, acc -> 
      url(coll_name, options)
      |> Client.put(docs)
      |> Kernel.++(acc)
    end)
  end
  
  def replace(document, options) do
    url(document._id, options)
    |> Client.put(document._data)
    |> to_document
  end
    
  def to_document(doc) do
    struct(Document, Client.decode_data(doc, Document))
  end

  defp url(path), do: url(path, nil, [])  
  defp url(path, options) when is_list(options), do: url(path, nil, options)
  defp url(path, database) when is_map(database), do: url(path, database, [])
  # defp url(path, database\\nil, options\\[])
  defp url(path, database, options) do
    case database do
      nil -> "/_api/document/#{path}"
      db when is_map(db) -> "/_db/#{db.name}/_api/document/#{path}"
    end
    |> Xarango.Connection.url(options)
  end
  
  defp docs_per_collection(documents) do
    documents
    |> Enum.reduce(%{}, fn doc, acc -> 
      coll_name = String.replace(doc._id, ~r/([^\/]+)\/.*/, "\\1")
      docs = Map.get(acc, coll_name, [])
      Map.put(acc, coll_name, docs ++ [doc])
    end)
  end
  
  defp ids_per_collection(documents) do
    documents
    |> Enum.reduce(%{}, fn doc, acc -> 
      coll_name = String.replace(doc._id, ~r/([^\/]+)\/.*/, "\\1")
      ids = Map.get(acc, coll_name, [])
      Map.put(acc, coll_name, ids ++ [doc._id])
    end)
  end

end


