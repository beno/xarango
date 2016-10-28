defmodule Xarango.Edge do
  
  defstruct [:_key, :_id, :_rev, :_oldRev, :_data, :_from, :_to]
  
  alias Xarango.Edge
  import Xarango.Client
  use Xarango.URI, prefix: "gharial"
  
  def edge(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> get
    |> to_edge
  end 
  
  def create(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}")
    |> post(edge)
    |> to_edge
  end
  
  def update(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> patch(edge._data)
    |> to_edge
  end
  
  def replace(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> put(Map.take(edge, [:_to, :_from, :_data]))
    |> to_edge
  end
  
  def destroy(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> delete
  end 
  # 
  # def edges(collection, [vertex: _] = options) do
  #   url(collection.id, options)
  #   |> get
  #   |> Enum.map(&to_edge(&1))
  # end
  
  def to_edge(edge) do
    struct(Edge, decode_data(Map.get(edge, :edge, edge), Edge))
  end
  
end