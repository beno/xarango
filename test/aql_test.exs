defmodule AQLTest do
  use ExUnit.Case
#  import Xarango.TestHelper

  alias Xarango.AQL

  defp coll(name\\"products") do
    %Xarango.Collection{name: name}
  end

  defp graph_node(id) do
    %{vertex: %{_id: id}}
  end

  defp graph(name) do
    %Xarango.Graph{name: name}
  end


  test "aql filter" do
    q = AQL.from(coll())
    |> AQL.filter([foo: "bar", size: 4])
    |> AQL.to_aql
    assert q == "FOR x IN products FILTER x.foo == 'bar' FILTER x.size == 4 RETURN x"
  end

  test "aql limit" do
    q = AQL.from(coll())
    |> AQL.limit(100)
    |> AQL.to_aql
    assert q == "FOR x IN products LIMIT 100 RETURN x"
  end

  test "aql limit and skip" do
    q = AQL.from(coll())
    |> AQL.limit(50, 10)
    |> AQL.to_aql
    assert q == "FOR x IN products LIMIT 10, 50 RETURN x"
  end

  test "aql sort" do
    q = AQL.from(coll())
    |> AQL.sort(:name)
    |> AQL.to_aql
    assert q == "FOR x IN products SORT x.name ASC RETURN x"
  end

  test "aql sort multiple ascending" do
    q = AQL.from(coll())
    |> AQL.sort([:name, :age], :asc)
    |> AQL.to_aql
    assert q == "FOR x IN products SORT x.name, x.age ASC RETURN x"
  end

  test "aql all" do
    q = AQL.from(coll())
    |> AQL.limit(9)
    |> AQL.sort([:name, :age])
    |> AQL.filter([foo: "bar", size: 4])
    |> AQL.where([age: 21])
    |> AQL.to_aql
    assert q == "FOR x IN products FILTER x.foo == 'bar' FILTER x.size == 4 FILTER x.age == 21 SORT x.name, x.age ASC LIMIT 9 RETURN x"
  end

  test "aql graph any" do
    q = AQL.any(graph_node("movies/TheMatrix"), :actsIn)
    |> AQL.options([bfs: true, uniqueVertices: "global"])
    |> AQL.to_aql
    assert q == "FOR x IN ANY 'movies/TheMatrix' actsIn OPTIONS {bfs: true, uniqueVertices: 'global'} RETURN x"
  end

  test "aql graph outbound vertices" do
    q = AQL.outbound(graph_node("movies/TheMatrix"), :actsIn)
    |> AQL.options([bfs: true, uniqueVertices: "global"])
    |> AQL.graph(graph("cinema"))
    |> AQL.to_aql
    assert q == "FOR x IN OUTBOUND 'movies/TheMatrix' actsIn GRAPH 'cinema' OPTIONS {bfs: true, uniqueVertices: 'global'} RETURN x"
  end

  test "aql graph inbound vertices" do
    q = AQL.inbound(graph_node("movies/TheMatrix"), :actsIn)
    |> AQL.graph("cinema")
    |> AQL.options([bfs: true, uniqueVertices: "global"])
    |> AQL.to_aql
    assert q == "FOR x IN INBOUND 'movies/TheMatrix' actsIn GRAPH 'cinema' OPTIONS {bfs: true, uniqueVertices: 'global'} RETURN x"
  end

  test "aql graph outbound relationships" do
    q = AQL.outbound(graph_node("actors/SeanConnery"), :actsIn, graph_node("movies/TheMatrix"))
    |> AQL.graph(graph("cinema"))
    |> AQL.to_aql
    assert q == "FOR x, y IN OUTBOUND SHORTEST_PATH 'actors/SeanConnery' TO 'movies/TheMatrix' actsIn GRAPH 'cinema' RETURN [x, y]"
  end

  test "aql graph inbound relationships" do
    q = AQL.inbound(graph_node("movies/TheMatrix"), :actsIn, graph_node("actors/SeanConnery"))
    |> AQL.graph("cinema")
    |> AQL.to_aql
    assert q == "FOR x, y IN INBOUND SHORTEST_PATH 'movies/TheMatrix' TO 'actors/SeanConnery' actsIn GRAPH 'cinema' RETURN [x, y]"
  end



end
