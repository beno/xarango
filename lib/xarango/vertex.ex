defmodule Xarango.Vertex do

  defstruct [:_id, :_key, :_rev, :_oldRev, :_data]
  
  alias Xarango.Vertex
  import Xarango.Client
  use Xarango.URI, prefix: "gharial"
  
  def vertex(vertex, collection, graph, database\\nil) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}", database)
    |> get
    |> to_vertex
  end 
  
  def create(vertex, collection, graph, database\\nil) do
    url("#{graph.name}/vertex/#{collection.collection}", database)
    |> post(vertex._data)
    |> to_vertex
  end
  
  def update(vertex, collection, graph, database\\nil) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}", database)
    |> patch(vertex._data)
    |> to_vertex
  end
  
  def replace(vertex, collection, graph, database\\nil) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}", database)
    |> put(vertex._data)
    |> to_vertex
  end
  
  def destroy(vertex, collection, graph, database\\nil) do
    url("#{graph.name}/vertex/#{collection.collection}/#{vertex._key}", database)
    |> delete
  end 
  
  def to_vertex(data) do
    data = Map.get(data, :vertex, data)
    struct(Vertex, decode_data(data, Vertex))
  end
  
end