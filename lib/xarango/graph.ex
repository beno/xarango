defmodule Xarango.Graph do
  
  defstruct [:_key, :_id, :_rev, :name, :edgeDefinitions, :orphanCollections]
  
  import Xarango.Client
  use Xarango.URI, prefix: "gharial"
  
  def graphs(database\\nil) do
    url(database)
    |> get
    |> Map.get(:graphs)
    |> Enum.map(&to_graph(&1))
  end
  
  def graph(graph, database\\nil, options\\[]) do
    url(graph.name, database, options)
    |> get
    |> to_graph
  end
  
  def create(graph, database\\nil, options\\[]) do
    url("", database, options)
    |> post(graph)
    |> to_graph
  end
  
  def destroy(graph, database\\nil, options\\[]) do
    url(graph.name, database, options)
    |> delete
  end
  
  def __destroy_all(database\\nil) do
    graphs(database)
    |> Enum.each(&destroy(&1))
  end

  def vertex_collections(graph, database\\nil) do
    url("#{graph.name}/vertex", database)
    |> get
    |> Map.get(:collections)
  end
  
  def add_vertex_collection(graph, collection, database\\nil) do
    url("#{graph.name}/vertex", database)
    |> post(collection)
    |> to_graph
  end
  
  def remove_vertex_collection(graph, collection, database\\nil) do
    url("#{graph.name}/vertex/#{collection.collection}", database)
    |> delete
    |> to_graph
  end
  
  def edge_definitions(graph, database\\nil) do
    url("#{graph.name}/edge", database)
    |> get
    |> Map.get(:collections)
  end
  
  def add_edge_definition(graph, edge_def, database\\nil) do
    url("#{graph.name}/edge", database)
    |> post(edge_def)
    |> to_graph
  end

  def remove_edge_definition(graph, edge_def, database\\nil) do
    url("#{graph.name}/edge/#{edge_def.collection}", database)
    |> delete  
    |> to_graph
  end
  
  def replace_edge_definition(graph, edge_def, database\\nil) do
    url("#{graph.name}/edge/#{edge_def.collection}", database)
    |> put(edge_def)
    |> to_graph
  end
  
  def ensure(graph, database\\nil) do
    try do
      graph(graph, database)
    rescue
      Xarango.Error -> create(graph, database)
    end
  end
  
  defp to_graph(graph_data) do
    graph_data =
      graph_data 
      |> Map.get(:graph, graph_data)
      |> ensure_name
      |> to_edge_defs
    struct(Xarango.Graph, graph_data)
  end
  
  defp ensure_name(graph_data) do
    case Map.get(graph_data, :name) do
      nil ->
        name = graph_data[:_key] || String.replace(graph_data[:_id], ~r{[^/]+/(.*)}, "\\1")
        Map.put(graph_data, :name, name)
      _ -> graph_data
    end
  end
  
  defp to_edge_defs(graph_data) do
    edges = graph_data[:edgeDefinitions] || []
    graph_data
    |> Map.put(:edgeDefinitions, Enum.map(edges, &struct(Xarango.EdgeDefinition, &1)))
  end  
  
end

defmodule Xarango.VertexCollection do
  
  defstruct [:collection]
  
  def ensure(collection, graph, database\\nil) do
    graph = Xarango.Graph.ensure(graph, database)
    IO.inspect Enum.member?(graph.orphanCollections, collection.collection)
    case Enum.member?(graph.orphanCollections, collection.collection) do
      false ->
        Xarango.Graph.add_vertex_collection(graph, collection, database)
        collection
      true -> collection
    end
  end
  
end

defmodule Xarango.EdgeCollection do

  defstruct [:collection]

end

defmodule Xarango.EdgeDefinition do

  defstruct [:collection, :from, :to]

end




