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
      |> Graph.add_vertex_collection(collection)
    result = Vertex.create(vertex_, collection, graph)
    assert String.starts_with?(result._id, collection.collection)
  end
  
  test "get vertex" do
    source = vertex_
    collection = vertex_collection_
    graph = Graph.create(graph_)
      |> Graph.add_vertex_collection(collection)
    vertex = Vertex.create(source, collection, graph)
    result = Vertex.vertex(vertex, collection, graph)
    assert source._data == result._data
  end
  
  test "modify vertex" do
    new_data = %{foo: "Foo"}
    source = vertex_
    collection = vertex_collection_
    graph = Graph.create(graph_)
      |> Graph.add_vertex_collection(collection)
    vertex = Vertex.create(source, collection, graph)
    new_vertex = %Vertex{ vertex | _data: new_data}
    vertex = Vertex.update(new_vertex, collection, graph)
    vertex = Vertex.vertex(vertex, collection, graph)
    assert vertex._data == Map.merge(source._data, new_data)
  end
  
  test "replace vertex" do
    new_data = %{foo: "Foo"}
    source = vertex_
    collection = vertex_collection_
    graph = Graph.create(graph_)
      |> Graph.add_vertex_collection(collection)
    vertex = Vertex.create(source, collection, graph)
    new_vertex = %Vertex{ vertex | _data: new_data}
    vertex = Vertex.replace(new_vertex, collection, graph)
    vertex = Vertex.vertex(vertex, collection, graph)
    assert vertex._data == new_data
  end
  
  test "destroy vertex" do
    collection = vertex_collection_
    graph = Graph.create(graph_)
      |> Graph.add_vertex_collection(collection)
    vertex = Vertex.create(vertex_, collection, graph)
    result = Vertex.destroy(vertex, collection, graph)
    assert result[:error] == false
    assert result[:removed] == true
  end
  
end