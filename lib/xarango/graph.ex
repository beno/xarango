defmodule Xarango.Graph do
  
  defstruct [:_key, :_id, :_rev, :name, :edgeDefinitions, :orphanCollections]
  
  alias Xarango.Client
  
  def graphs do
    url()
    |> Client.get
    |> Map.get(:graphs)
    |> Enum.map(&to_graph(&1))
  end
  
  def graph(graph, options\\[]) do
    url(graph.name, options)
    |> Client.get
    |> to_graph
  end
  
  def create(graph, options\\[]) do
    url("", options)
    |> Client.post(graph)
    |> to_graph
  end
  
  def destroy(graph, options\\[]) do
    url(graph.name, options)
    |> Client.delete
  end
  
  def __destroy_all do
    graphs
    |> Enum.each(&destroy(&1))
  end

  def vertex_collections(graph) do
    url("#{graph.name}/vertex")
    |> Client.get
    |> Map.get(:collections)
  end
  
  def add_vertex_collection(graph, collection) do
    url("#{graph.name}/vertex")
    |> Client.post(collection)
    |> to_graph
  end
  
  def remove_vertex_collection(graph, collection) do
    url("#{graph.name}/vertex/#{collection.collection}")
    |> Client.delete
    |> to_graph
  end
  
  def edge_definitions(graph) do
    url("#{graph.name}/edge")
    |> Client.get
    |> Map.get(:collections)
  end
  
  def add_edge_definition(graph, edge_def) do
    url("#{graph.name}/edge")
    |> Client.post(edge_def)
    |> to_graph
  end

  def remove_edge_definition(graph, edge_def) do
    url("#{graph.name}/edge/#{edge_def.collection}")
    |> Client.delete  
    |> to_graph
  end
  
  def replace_edge_definition(graph, edge_def) do
    url("#{graph.name}/edge/#{edge_def.collection}")
    |> Client.put(edge_def)
    |> to_graph
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
  
  # defp to_vertex_coll(vertex_data) do
  #   vertex_data =
  #     vertex_data
  #     |> Map.get(:vertex, vertex_data)
  #   struct(Xarango.VertexCollection, vertex_data)
  # 
  # end
  
  defp url(path\\"", options\\[]) do
    Xarango.Connection.url("/_api/gharial/#{path}", options)
  end
  
end

defmodule Xarango.VertexCollection do
  
  defstruct [:collection]
  
end

defmodule Xarango.EdgeCollection do

  defstruct [:collection]

end


defmodule Xarango.EdgeDefinition do

  defstruct [:collection, :from, :to]

end




