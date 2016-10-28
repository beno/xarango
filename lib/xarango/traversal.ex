defmodule Xarango.Traversal do
  
  defstruct [:sort, :direction, :minDepth, :startVertex, :visitor, :itemOrder, 
    :strategy, :filter, :init, :maxIterations, :maxDepth, :uniqueness, :graphName, :expander, :edgeCollection]
  
  import Xarango.Client
  use Xarango.URI, [prefix: "traversal"]
  
  def traverse(traversal, options\\[]) do
    url("", options)
    |> post(traversal)
    |> Xarango.TraversalResult.to_result
  end  
  
end

defmodule Xarango.TraversalResult do
  
  defstruct [:vertices, :paths]
  
  def to_result(data) do
    vertices = get_in(data, [:result, :visited, :vertices])
    paths = get_in(data, [:result, :visited, :paths])
    data = data
      |> get_in([:result, :visited])
      |> Map.put(:vertices, Enum.map(vertices, &Xarango.Vertex.to_vertex(&1)))
      |> Map.put(:paths, Enum.map(paths, &Xarango.Path.to_path(&1)))
    struct(Xarango.TraversalResult, data)
  end

end

defmodule Xarango.Path do
  
  defstruct [:vertices, :edges]
  
  def to_path(data) do
    vertices = get_in(data, [:vertices])
    edges = get_in(data, [:edges])
    data = data
      |> Map.put(:vertices, Enum.map(vertices, &Xarango.Vertex.to_vertex(&1)))
      |> Map.put(:edges, Enum.map(edges, &Xarango.Edge.to_edge(&1)))
    struct(Xarango.Path, data)
  end

end
