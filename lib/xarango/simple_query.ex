defmodule Xarango.SimpleQuery do
  
  defstruct [:collection, :skip, :limit, :example, :keys, :options, :newValue, :right, :left,
    :attribute, :closed, :latitude, :longitude, :latitude1, :longitude1, :latitude2, :longitude2, :radius]
  
  alias Xarango.SimpleQuery
  alias Xarango.Client
  alias Xarango.Document
  alias Xarango.Query
  
  def all(query) do
    url("all")
    |> Xarango.Client.put(query)
    |> to_result
  end
  
  def by_example(%SimpleQuery{example: example} = query) when not is_nil(example) do
    url("by-example")
    |> Client.put(query)
    |> to_result
  end
  
  def first_example(%SimpleQuery{example: example} = query) when not is_nil(example) do
    url("first-example")
    |> Client.put(query)
    |> Map.get(:document)
    |> Document.to_document
  end
  
  def find_by_keys(query) do
    url("lookup-by-keys")
    |> Client.put(query)
    |> Map.get(:documents)
    |> Enum.map(&Document.to_document(&1))
  end
  
  def random(query) do
    url("any")
    |> Client.put(query)
    |> Map.get(:document)
    |> Document.to_document
  end

  def destroy_by_keys(query) do
    url("remove-by-keys")
    |> Client.put(query)
  end

  def destroy_by_example(query) do
    url("remove-by-example")
    |> Client.put(query)
  end
  
  def replace_by_example(query) do
    url("replace-by-example")
    |> Client.put(query)
  end
  
  def update_by_example(query) do
    url("update-by-example")
    |> Client.put(query)
  end

  def range(query) do
    q = "FOR doc IN #{query.collection} FILTER doc.@attribute >= @left && doc.@attribute < @right  LIMIT @skip, @limit RETURN doc"
    vars = Map.take(query, [:left, :right, :attribute, :skip, :limit])
    %Query{query: q, bindVars: vars}
    |> Query.query
    |> Map.get(:result)
    |> Enum.map(&Document.to_document(&1))
  end
  
  def near(query) do
    q = "FOR doc IN NEAR(#{query.collection}, @latitude, @longitude, @limit) RETURN doc"
    vars = Map.take(query, [:latitude, :longitude, :limit])
    %Query{query: q, bindVars: vars}
    |> Query.query
    |> Map.get(:result)
    |> Enum.map(&Document.to_document(&1))
  end
  
  def within(query) do
    q = "FOR doc IN WITHIN(#{query.collection}, @latitude, @longitude, @radius, @attribute) RETURN doc"
    %Query{query: q, bindVars: Map.take(query, [:latitude, :longitude, :radius, :attribute])}
    |> Query.query
    |> Map.get(:result)
    |> Enum.map(&Document.to_document(&1))
  end
  
  def within_rectangle(query) do
    url("within-rectangle")
    |> Client.put(query)
    |> Map.get(:result)
    |> Enum.map(&Document.to_document(&1))
  end
    
  defp to_result(data) do
    struct(Xarango.QueryResult, data)
  end
    
  
  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/simple/#{path}", options)
  end
  
end
