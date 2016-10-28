defmodule Xarango.Vertex do

  defstruct [:_id, :_key, :_rev, :_oldRev, :_data]
  
  alias Xarango.Vertex
  import Xarango.Client
  use Xarango.URI, prefix: "gharial"
  
  def vertex(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> get
    |> to_vertex
  end 
  
  def create(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}")
    |> post(vertex._data)
    |> to_vertex
  end
  
  def update(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> patch(vertex._data)
    |> to_vertex
  end
  
  def replace(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> put(vertex._data)
    |> to_vertex
  end
  
  def destroy(graph, collection, vertex) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}")
    |> delete
  end 
  
  def to_vertex(data) do
    data = Map.get(data, :vertex, data)
    struct(Vertex, decode_data(data, Vertex))
  end
  
end