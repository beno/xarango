defmodule Xarango.EdgeCollection do

  defstruct [:collection]

end

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

  def to_edge(edges) when is_list(edges) do
    Enum.map(edges, &to_edge(&1))
  end
  def to_edge(edge) do
    struct(Edge, decode_data(Map.get(edge, :edge, edge), Edge))
  end

  def collection(edge) do
    [collection, _] = String.split(edge._id, "/")
    %Xarango.EdgeCollection{collection: collection}
  end

end

defmodule Xarango.EdgeDefinition do

  defstruct [:collection, :from, :to]

  def ensure(edge_definition, graph, database\\nil) do
    graph = Xarango.Graph.ensure(graph, database)
    Enum.find(graph.edgeDefinitions, fn edge_def ->
      edge_def.collection == edge_definition.collection
    end)
    |> case do
      nil ->
        Xarango.Graph.add_edge_definition(graph, edge_definition, database)
        edge_definition
      edge_def ->
        if equal?(edge_def, edge_definition) do
          edge_def
        else
          from = edge_def.from ++ edge_definition.from |> Enum.uniq
          to = edge_def.to ++ edge_definition.to |> Enum.uniq
          edge_definition = %Xarango.EdgeDefinition{ edge_def | from: from, to: to }
          Xarango.Graph.replace_edge_definition(graph, edge_definition, database)
          edge_definition
        end
    end
  end

  defp equal?(ed1, ed2) do
    ed1.from -- (ed1.from -- ed2.from) != [] &&
    ed1.to -- (ed1.to -- ed2.to) != [] &&
    ed1.collection == ed2.collection
  end

end
