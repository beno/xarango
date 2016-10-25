defmodule EdgeTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Edge
  alias Xarango.Graph
  
  setup do
    on_exit fn ->
      Graph.__destroy_all
      Xarango.Collection.__destroy_all
    end
  end
  
  test "create edge" do
    graph = Graph.create(graph_)
    {collection, _, edge} = _create_edge(graph)
    assert String.starts_with?(edge._id, collection.collection)
  end
  
  test "get edge" do
    graph = Graph.create(graph_)
    {collection, source, edge} = _create_edge(graph)
    edge = Edge.edge(graph, collection, edge)
    assert source._data == edge._data
  end
  
  test "modify edge" do
    graph = Graph.create(graph_)
    new_data = %{foo: "Foo"}
    {collection, source, edge} = _create_edge(graph)
    new_edge = %Edge{ edge | _data: new_data}
    egde = Edge.update(graph, collection, new_edge)
    egde = Edge.edge(graph, collection, egde)
    assert egde._data == Map.merge(source._data, new_data)
  end

  test "replace edge" do
    graph = Graph.create(graph_)
    new_data = %{foo: "Foo"}
    {collection, _, edge} = _create_edge(graph)
    edge = Edge.edge(graph, collection, edge)
    new_edge = %Edge{ edge | _data: new_data}
    egde = Edge.replace(graph, collection, new_edge)
    egde = Edge.edge(graph, collection, egde)
    assert egde._data == new_data
  end
  
  test "destroy edge" do
    graph = Graph.create(graph_)
    {collection, _, edge} = _create_edge(graph)
    result = Edge.destroy(graph, collection, edge)
    assert result[:error] == false
    assert result[:removed] == true
  end

  defp _create_edge(graph) do
    edge_coll = edge_collection_
    {vertex_coll, from, to} = _create_vertices(graph)
    source = %Edge{ edge_ | _from: from._id, _to: to._id }
    edge_def = %Xarango.EdgeDefinition{collection: edge_coll.collection, from: [vertex_coll.collection], to: [vertex_coll.collection]}
    graph = Graph.add_edge_definition(graph, edge_def)
    edge = Edge.create(graph, edge_coll, source)
    {edge_coll, source, edge}
  end
  
  defp _create_vertices(graph) do
    vertex_coll = vertex_collection_
    graph = Xarango.Graph.add_vertex_collection(graph, vertex_coll)
    from = Xarango.Vertex.create(graph, vertex_coll, vertex_)
    to = Xarango.Vertex.create(graph, vertex_coll, vertex_)
    {vertex_coll, from, to}
  end  

end