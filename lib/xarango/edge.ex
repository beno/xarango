defmodule Xarango.Edge do
  
  defstruct [:_key, :_id, :_rev, :_oldRev, :_data, :_from, :_to]
  
  alias Xarango.Edge
  import Xarango.Client
  use Xarango.URI, prefix: "gharial"
  
  def edge(edge, collection, graph, database\\nil) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}", database)
    |> get
    |> to_edge
  end 
  
  # def edges(collection, database\\nil, [vertex: vertex] = options) do
  #   url(collection.id, database, options)
  #   |> get
  #   |> Enum.map(&to_edge(&1))
  # end

  def create(edge, collection, graph, database\\nil) do
    url("#{graph.name}/edge/#{collection.collection}", database)
    |> post(edge)
    |> to_edge
  end
  
  def update(edge, collection, graph, database\\nil) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}", database)
    |> patch(edge._data)
    |> to_edge
  end
  
  def replace(edge, collection, graph, database\\nil) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}", database)
    |> put(Map.take(edge, [:_to, :_from, :_data]))
    |> to_edge
  end
  
  def destroy(edge, collection, graph, database\\nil) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}", database)
    |> delete
  end 
  
  def to_edge(edge) do
    struct(Edge, decode_data(Map.get(edge, :edge, edge), Edge))
  end
  
end