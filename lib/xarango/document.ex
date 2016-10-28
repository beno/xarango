defmodule Xarango.Document do
  
  defstruct [:_key, :_id, :_rev, :_oldRev, :_data]
  
  alias Xarango.Document
  import Xarango.Client
  use Xarango.URI, prefix: "document"
  
  def document(document, database\\nil) do
    url(document._id, database)
    |> get
    |> to_document
  end
  
  def documents(collection, database\\nil) do
    %Xarango.SimpleQuery{collection: collection.name}
    |> Xarango.SimpleQuery.all(database)
    |> Map.get(:result)
    |> Enum.map(&struct(Document, &1))
  end

  def create(document, collection), do: create(document, collection, nil, [])
  def create(document, collection, options) when is_list(options), do: create(document, collection, nil, options)
  def create(document, collection, database) when is_map(database), do: create(document, collection, database, [])
  def create(documents, collection, database, options) when is_list(documents) do
    data = Enum.map(documents, &Map.get(&1, :_data))
    url(collection.name, database, options)
    |> post(data)
    |> Enum.map(&struct(Document, &1))
  end
  def create(document, collection, database, options) do
    url(collection.name, database, options)
    |> post(document._data)
    |> case do
      %{new: new_doc} -> new_doc
      doc -> doc
    end
    |> to_document
  end

  def destroy(document), do: destroy(document, nil, [])
  def destroy(document, options) when is_list(options), do: destroy(document, nil, options)
  def destroy(document, database) when is_map(database), do: destroy(document, database, [])    
  def destroy(documents, database, options) when is_list(documents) do
    documents
    |> ids_per_collection
    |> Enum.reduce([], fn {coll_name, ids}, acc -> 
      url(coll_name, database, options)
      |> delete(ids)
      |> Kernel.++(acc)
    end)
  end
  def destroy(document, database, options) do
    url(document._id, database, options)
    |> delete
  end
  
  def __destroy_all do
    Xarango.Collection.collections
    |> Enum.reject(&Map.get(&1, :isSystem))
    |> Enum.map(&documents(&1))
    |> Enum.each(&destroy(&1))
  end
  
  def update(document), do: update(document, nil, [])
  def update(document, options) when is_list(options), do: update(document, nil, options)
  def update(document, database) when is_map(database), do: update(document, database, [])    
  def update(documents, database, options) when is_list(documents) do
    documents
    |> docs_per_collection
    |> Enum.reduce([], fn {coll_name, docs}, acc -> 
      url(coll_name, database, options)
      |> patch(docs)
      |> Kernel.++(acc)
    end)
  end
  def update(document, database, options) do
    url(document._id, database, options)
    |> patch(document._data)
    |> to_document
  end
  
  def replace(document), do: replace(document, nil, [])
  def replace(document, options) when is_list(options), do: replace(document, nil, options)
  def replace(document, database) when is_map(database), do: replace(document, database, [])    
  def replace(documents, database, options) when is_list(documents) do
    documents
    |> docs_per_collection
    |> Enum.reduce([], fn {coll_name, docs}, acc -> 
      url(coll_name, database, options)
      |> put(docs)
      |> Kernel.++(acc)
    end)
  end
  def replace(document, database, options) do
    url(document._id, database, options)
    |> put(document._data)
    |> to_document
  end
    
  def to_document(doc) do
    struct(Document, decode_data(doc, Document))
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


