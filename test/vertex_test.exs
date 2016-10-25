defmodule VertexTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Graph
  alias Xarango.Vertex
  
  setup do
    on_exit fn ->
      Graph.__destroy_all
      Xarango.Collection.__destroy_all
    end
  end

  test "create vertex" do
    collection = vertex_collection_
    graph = Graph.create(graph_)
    graph = Graph.add_vertex_collection(graph, collection)
    result = Vertex.create(graph, collection, vertex_)
    assert String.starts_with?(result._id, collection.collection)
  end
  
  test "get vertex" do
    source = vertex_
    collection = vertex_collection_
    graph = Graph.create(graph_)
    graph = Graph.add_vertex_collection(graph, collection)
    vertex = Vertex.create(graph, collection, source)
    result = Vertex.vertex(graph, collection, vertex)
    assert source._data == result._data
  end
  
  test "modify vertex" do
    new_data = %{foo: "Foo"}
    source = vertex_
    collection = vertex_collection_
    graph = Graph.create(graph_)
    graph = Graph.add_vertex_collection(graph, collection)
    vertex = Vertex.create(graph, collection, source)
    newvertex_ = %Vertex{ vertex | _data: new_data}
    vertex = Vertex.update(graph, collection, newvertex_)
    vertex = Vertex.vertex(graph, collection, vertex)
    assert vertex._data == Map.merge(source._data, new_data)
  end
  
  test "replace vertex" do
    new_data = %{foo: "Foo"}
    source = vertex_
    collection = vertex_collection_
    graph = Graph.create(graph_)
    graph = Graph.add_vertex_collection(graph, collection)
    vertex = Vertex.create(graph, collection, source)
    newvertex_ = %Vertex{ vertex | _data: new_data}
    vertex = Vertex.replace(graph, collection, newvertex_)
    vertex = Vertex.vertex(graph, collection, vertex)
    assert vertex._data == new_data
  end
  
  test "destroy vertex" do
    collection = vertex_collection_
    graph = Graph.create(graph_)
    graph = Graph.add_vertex_collection(graph, collection)
    vertex = Vertex.create(graph, collection, vertex_)
    result = Vertex.destroy(graph, collection, vertex)
    assert result[:error] == false
    assert result[:removed] == true
  end

end