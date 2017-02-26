defmodule Xarango.Edge do

  defstruct [:_key, :_id, :_rev, :_oldRev, :_data, :_from, :_to]

  alias Xarango.Edge
  import Xarango.Client
  use Xarango.URI, prefix: "gharial"


  def edge(%Edge{_id: id}, database\\nil) when is_binary(id) do
    Xarango.Document.url(id, database)
    |> get
    |> to_edge
  end

  def edge(edge, collection, graph, database\\nil) do
    url = case edge do
      %{_id: id} -> id
      %{_key: key} -> "#{collection.collection}/#{key}"
      _ -> raise Xarango.Error, message: "Edge not specified"
    end
    url("#{graph.name}/edge/#{url}", database)
    |> get
    |> to_edge
  end

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
