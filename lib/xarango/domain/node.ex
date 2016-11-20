defmodule Xarango.Domain.Node do
  
  alias Xarango.Vertex
  alias Xarango.EdgeCollection
  alias Xarango.SimpleQuery
  
  defmacro __using__(options\\[]) do
    graph = options[:graph]
    quote do
      alias Xarango.Domain.Node
      defstruct vertex: %Xarango.Vertex{}
      defp _graph_module(options) do
        case options[:graph] || unquote(graph) do
          nil -> raise Xarango.Error, message: "graph not set for #{__MODULE__}"
          module -> module
        end
      end
      defp _graph(options) do
        %Xarango.Graph{name: Xarango.Util.name_from(_graph_module(options))}
      end
      defp _database(options) do
        apply(_graph_module(options), :_database, [])
      end
      defp _collection, do: %Xarango.VertexCollection{collection: Xarango.Util.name_from(__MODULE__)}
      def create(data, options\\[]) do
        apply(_graph_module(options), :ensure, [])
        Node.create(data, _collection, _graph(options), _database(options)) |> to_node
      end
      def one(params, options\\[]), do: Node.one(params, _collection, _graph(options), _database(options)) |> to_node
      def list(params, options\\[]), do: Node.list(params, _collection, _graph(options), _database(options)) |> to_nodes
      def replace(node, data, options\\[]), do: Node.replace(node, data, _collection, _graph(options), _database(options)) |> to_node
      def update(node, data, options\\[]), do: Node.update(node, data, _collection, _graph(options), _database(options)) |> to_node
      def destroy(node, options\\[]), do: Node.destroy(node, _collection, _graph(options), _database(options))
      def fetch(node, field) do
        case field do
          :id -> {:ok, node.vertex._id}
          "id" -> {:ok, node.vertex._id}
          value -> {:ok, get_in(node.vertex._data, List.wrap(field))}
        end
      end
      defp to_node(vertex), do: struct(__MODULE__, vertex: vertex)
      defp to_nodes(vertices), do: vertices |> Enum.map(&struct(__MODULE__, vertex: &1))
    end
  end
  
  def create(data, collection, graph, database) do
    vc = Xarango.VertexCollection.ensure(collection, graph, database)
    Vertex.create(%Vertex{_data: data}, vc, graph, database)
    |> Vertex.vertex(vc, graph, database)
  end
  
  def one(params, collection, edges, _graph, database) when is_list(edges) do
    SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.collection}, database) |> to_vertex
  end
  def one(params, collection, _graph, database) do
    SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.collection}, database) |> to_vertex
  end
  
  def list(params, collection, _graph, database) do
    SimpleQuery.by_example(%SimpleQuery{example: params, collection: collection.collection}, database)
    |> Enum.map(&to_vertex(&1))
  end
  
  def replace(node, data, collection, graph, database) do
    %{ node.vertex | _data: data }
    |> Vertex.replace(collection, graph, database)
    |> Vertex.vertex(collection, graph, database)
  end
  
  def update(node, data, collection, graph, database) do
    %{ node.vertex | _data: data }
    |> Vertex.update(collection, graph, database)
    |> Vertex.vertex(collection, graph, database)
  end
  
  def destroy(node, collection, graph, database) do
    node.vertex
    |> Vertex.destroy(collection, graph, database)
  end
  
  defp to_vertex(document) do
    doc = Map.from_struct(document)
    struct(Xarango.Vertex, doc) 
  end
      
end