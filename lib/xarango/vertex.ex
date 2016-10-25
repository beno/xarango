defmodule Xarango.Vertex do

  defstruct [:_id, :_key, :_rev, :_oldRev, :_data]
  
  alias Xarango.Vertex
  alias Xarango.Client
  
  def vertex(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> Client.get
    |> to_vertex
  end 
  
  def create(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}")
    |> Client.post(vertex._data)
    |> to_vertex
  end
  
  def update(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> Client.patch(vertex._data)
    |> to_vertex
  end
  
  def replace(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> Client.put(vertex._data)
    |> to_vertex
  end
  
  def destroy(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> Client.delete
  end 
  
  def to_vertex(data) do
    data = Map.get(data, :vertex, data)
    struct(Vertex, Client.decode_data(data, Vertex))
  end
  
  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/gharial/#{path}", options)
  end

end