defmodule TraversalTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Graph
  alias Xarango.Edge
  alias Xarango.Vertex
  alias Xarango.Traversal

  setup do
    Graph.__destroy_all
    Xarango.Collection.__destroy_all
    on_exit fn ->
      Graph.__destroy_all
      Xarango.Collection.__destroy_all
    end
  end

  test "do traversal" do
    {graph, start_vertex} = _create_graph
    traversal = %Traversal{startVertex: start_vertex._id, graphName: graph.name, direction: "outbound"}
    result = Traversal.traverse(traversal)
    assert length(result.paths) == 4
    assert length(result.vertices) == 4
  end
  
  defp _create_graph do
    vc = vertex_collection_
    ec = edge_collection_
    g = Graph.create(graph_)
      |> Graph.add_vertex_collection(vc)
      |> Graph.add_edge_definition(%Xarango.EdgeDefinition{collection: ec.collection, from: [vc.collection], to: [vc.collection]})
    [alice, bob, charlie, dave, eve] = Enum.map(~w{alice, bob, charlie, dave, eve}, &Vertex.create(g, vc, person(&1)))
    [
      %Edge{_from: alice._id, _to: bob._id},
      %Edge{_from: bob._id, _to: charlie._id},
      %Edge{_from: bob._id, _to: dave._id},
      %Edge{_from: eve._id, _to: alice._id},
      %Edge{_from: eve._id, _to: bob._id}
    ]
    |> Enum.each(fn e ->
      Edge.create(g, ec, e)
    end)
    {g, alice}
  end
  
  defp person(name) do
    %Vertex{ vertex_ | _data: %{name: name}}
  end

end