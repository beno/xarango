defmodule Xarango.Traversal do

  defstruct [:sort, :direction, :minDepth, :startVertex, :visitor, :itemOrder,
    :strategy, :filter, :init, :maxIterations, :maxDepth, :uniqueness, :graphName, :expander, :edgeCollection]

  import Xarango.Client
  use Xarango.URI, prefix: "traversal"

  def traverse(traversal, database\\nil, options\\[]) do
    url("", database, options)
    |> post(traversal)
    |> Xarango.TraversalResult.to_result
  end

end

defmodule Xarango.TraversalResult do

  defstruct [:vertices, :paths]

  def to_result(data) do
    visited = get_in(data, [:result, :visited])
    result = visited
      |> Map.put(:vertices, Enum.map(visited[:vertices], &Xarango.Vertex.to_vertex(&1)))
      |> Map.put(:paths, Enum.map(visited[:paths], &Xarango.Path.to_path(&1)))
    struct(Xarango.TraversalResult, result)
  end

  def vertices_to(result), do: vertices(result, :to)
  def vertices_from(result), do: vertices(result, :from)
  def vertices(result, dir) do
    result.paths
   |> Enum.reduce([], fn path, vertices ->
      case path.edges do
        [] -> vertices
        _ -> vertices ++ target_vertices(path, dir)
      end
    end)
  end

  defp target_vertices(path, dir) do
    case dir do
      :to -> Enum.map(path.edges, fn %{_to: vertex_id} -> find_vertex(vertex_id, path) end )
      :from -> Enum.map(path.edges, fn %{_from: vertex_id} -> find_vertex(vertex_id, path) end )
    end
  end

  defp find_vertex(id, path) do
    path.vertices
    |> Enum.find(fn vertex -> vertex._id == id end)
  end

end

defmodule Xarango.Path do

  defstruct [:vertices, :edges]

  def to_path(data) do
    path = data
      |> Map.put(:vertices, Enum.map(data[:vertices], &Xarango.Vertex.to_vertex(&1)))
      |> Map.put(:edges, Enum.map(data[:edges], &Xarango.Edge.to_edge(&1)))
    struct(Xarango.Path, path)
  end

end
