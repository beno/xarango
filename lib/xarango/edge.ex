defmodule Xarango.Edge do
  
  defstruct [:_key, :_id, :_rev, :_oldRev, :_data, :_from, :_to]
  
  alias Xarango.Edge
  alias Xarango.Client
  
  def edge(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> Client.get
    |> to_edge
  end 
  
  def create(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}")
    |> Client.post(edge)
    |> to_edge
  end
  
  def update(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> Client.patch(edge._data)
    |> to_edge
  end
  
  def replace(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> Client.put(Map.take(edge, [:_to, :_from, :_data]))
    |> to_edge
  end
  
  def destroy(graph, collection, edge) do
    url("#{graph.name}/edge/#{collection.collection}/#{edge._key}")
    |> Client.delete
  end 
  # 
  # def edges(collection, [vertex: _] = options) do
  #   url(collection.id, options)
  #   |> Client.get
  #   |> Enum.map(&to_edge(&1))
  # end
  
  def to_edge(edge) do
    struct(Edge, Client.decode_data(Map.get(edge, :edge, edge), Edge))
  end
  
  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/gharial/#{path}", options)
  end

end