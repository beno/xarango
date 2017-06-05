defmodule GraphTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Graph

  setup do
    on_exit fn ->
      Graph.__destroy_all
      Xarango.Collection.__destroy_all
    end
  end

  test "list graphs" do
    graphs = Graph.graphs
    assert is_list(graphs)
  end

  test "create graph" do
    source = graph_()
    graph = Graph.create(source)
    assert graph.name == source.name
  end

  test "read graph" do
    graph = Graph.create(graph_())
    result = Graph.graph(graph)
    assert result.name == graph.name
  end

  test "destroy graph" do
    result = Graph.create(graph_())
      |> Graph.destroy
    assert result[:removed] == true
  end

  test "list vertex collections" do
    result = Graph.create(graph_())
      |> Graph.vertex_collections
    assert is_list(result)
  end

  test "list vertices" do
    collection = vertex_collection_()
    graph = Graph.create(graph_())
      |> Graph.add_vertex_collection(collection)
    Xarango.Vertex.create(%Xarango.Vertex{_data: %{foo: "bar"}}, collection, graph)
    Xarango.Vertex.create(%Xarango.Vertex{_data: %{bar: "foo"}}, collection, graph)
    vertices = Xarango.VertexCollection.vertices(collection)
    assert length(vertices) == 2
  end

  test "add vertex collection" do
    collection = vertex_collection_()
    graph = Graph.create(graph_())
      |> Graph.add_vertex_collection(collection)
    assert graph.orphanCollections == [collection.collection]
  end

  test "remove vertex collection" do
    collection = vertex_collection_()
    graph = Graph.create(graph_())
      |> Graph.add_vertex_collection(collection)
    graph = Graph.remove_vertex_collection(graph, collection)
    assert graph.orphanCollections == []
  end

  test "list edge definitions" do
    graph = Graph.create(graph_())
    edge_defs = Graph.edge_definitions(graph)
    assert is_list(edge_defs)
  end

  test "add edge definition" do
    edge_def = edge_def_()
    graph = Graph.create(graph_())
      |> Graph.add_edge_definition(edge_def)
    assert Enum.member?(graph.edgeDefinitions, edge_def)
  end

  test "replace edge definition" do
    edge_def = edge_def_()
    graph = Graph.create(graph_())
      |> Graph.add_edge_definition(edge_def)
    edge_def = %Xarango.EdgeDefinition{edge_def | to: ["jabba"]}
    result = Graph.replace_edge_definition(graph, edge_def)
    assert Enum.member?(result.edgeDefinitions, edge_def)
  end

  test "remove edge definition" do
    edge_def = edge_def_()
    graph = Graph.create(graph_())
      |> Graph.add_edge_definition(edge_def)
    assert Enum.member?(graph.edgeDefinitions, edge_def)
    graph = Graph.remove_edge_definition(graph, edge_def)
    refute Enum.member?(graph.edgeDefinitions, edge_def)
  end

end
