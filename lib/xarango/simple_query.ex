defmodule Xarango.SimpleQuery do
  
  defstruct [:collection, :skip, :limit, :example, :keys, :options, :newValue, :right, :left,
    :attribute, :closed, :latitude, :longitude, :latitude1, :longitude1, :latitude2, :longitude2, :radius, :query]
  
  alias Xarango.SimpleQuery
  alias Xarango.Document
  alias Xarango.Query
  import Xarango.Client
  use Xarango.URI, [prefix: "simple"]
  
  def all(query, database\\nil) do
    url("all", database)
    |> put(query)
    |> to_result
  end
  
  def by_example(%SimpleQuery{example: example} = query, database\\nil) when not is_nil(example) do
    url("by-example", database)
    |> put(query)
    |> to_result
  end
  
  def first_example(%SimpleQuery{example: example} = query, database\\nil) when not is_nil(example) do
    url("first-example", database)
    |> put(query)
    |> Map.get(:document)
    |> Document.to_document
  end
  
  def find_by_keys(query, database\\nil) do
    url("lookup-by-keys", database)
    |> put(query)
    |> Map.get(:documents)
    |> Enum.map(&Document.to_document(&1))
  end
  
  def random(query, database\\nil) do
    url("any", database)
    |> put(query)
    |> Map.get(:document)
    |> Document.to_document
  end

  def destroy_by_keys(query, database\\nil) do
    url("remove-by-keys", database)
    |> put(query)
  end

  def destroy_by_example(query, database\\nil) do
    url("remove-by-example", database)
    |> put(query)
  end
  
  def replace_by_example(query, database\\nil) do
    url("replace-by-example", database)
    |> put(query)
  end
  
  def update_by_example(query, database\\nil) do
    url("update-by-example", database)
    |> put(query)
  end

  def range(query, database\\nil) do
    q = "FOR doc IN #{query.collection} FILTER doc.@attribute >= @left && doc.@attribute < @right  LIMIT @skip, @limit RETURN doc"
    vars = Map.take(query, [:left, :right, :attribute, :skip, :limit])
    %Query{query: q, bindVars: vars}
    |> Query.query(database)
    |> to_documents
  end
  
  def near(query, database\\nil) do
    q = "FOR doc IN NEAR(#{query.collection}, @latitude, @longitude, @limit) RETURN doc"
    vars = Map.take(query, [:latitude, :longitude, :limit])
    %Query{query: q, bindVars: vars}
    |> Query.query(database)
    |> to_documents
  end
  
  def within(query, database\\nil) do
    q = "FOR doc IN WITHIN(#{query.collection}, @latitude, @longitude, @radius, @attribute) RETURN doc"
    vars = Map.take(query, [:latitude, :longitude, :radius, :attribute])
    %Query{query: q, bindVars: vars}
    |> Query.query(database)
    |> to_documents
  end
  
  def within_rectangle(query, database\\nil) do
    url("within-rectangle", database)
    |> put(query)
    |> to_documents
  end
  
  def fulltext(query, database\\nil) do
    q = "FOR doc IN FULLTEXT(#{query.collection}, @attribute, @query, @limit) RETURN doc"
    vars = Map.take(query, [:query, :limit, :attribute])
    %Query{query: q, bindVars: vars}
    |> Query.query(database)
    |> to_documents
  end
  
  defp to_documents(data) do
    data
    |> Map.get(:result)
    |> Enum.map(&Document.to_document(&1))
  end
    
  defp to_result(data) do
    struct(Xarango.QueryResult, data)
  end
  
end
