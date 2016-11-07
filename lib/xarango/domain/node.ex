defmodule Xarango.Domain.Node do

  alias Xarango.Vertex
  alias Xarango.SimpleQuery
  
  
  defmacro __using__(options) do
    database = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    graph = options[:graph]
    quote do
      alias Xarango.Domain.Node
      defstruct vertex: %Xarango.Vertex{}
      defp _database, do: %Xarango.Database{name: unquote(database)}
      defp _graph_module do
        case unquote(graph) do
          nil -> raise Xarango.Error, message: "graph not set for #{__MODULE__}"
          graph -> graph
        end
      end
      defp _graph(nil), do: %Xarango.Graph{name: Xarango.Util.name_from(_graph_module)}
      defp _graph(graph), do: %Xarango.Graph{name: Xarango.Util.name_from(graph)}
      defp _collection, do: %Xarango.VertexCollection{collection: Xarango.Util.name_from(__MODULE__)}
      def create(data, options\\[]), do: Node.create(data, _collection, _graph(options[:graph]), _database) |> to_node
      def one(params, options\\[]), do: Node.one(params, _collection, _graph(options[:graph]), _database) |> to_node
      def list(params, options\\[]), do: Node.list(params, _collection, _graph(options[:graph]), _database) |> to_nodes
      def replace(node, data, options\\[]), do: Node.replace(node, data, _collection, _graph(options[:graph]), _database) |> to_node
      def update(node, data, options\\[]), do: Node.update(node, data, _collection, _graph(options[:graph]), _database) |> to_node
      def destroy(node, options\\[]), do: Node.destroy(node, _collection, _graph(options[:graph]), _database)
      defp to_node(vertex), do: struct(__MODULE__, vertex: vertex)
      defp to_nodes(vertices), do: vertices |> Enum.map(&struct(__MODULE__, vertex: &1))
    end
  end
  
  def create(data, collection, graph, database) do
    graph.ensure()
    vc = Xarango.VertexCollection.ensure(collection, graph, database)
    Vertex.create(%Vertex{_data: data}, vc, graph, database)
    |> Vertex.vertex(vc, graph, database)
  end
  def one(params, collection, _graph, database) do
    document = SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.collection}, database)
    struct(__MODULE__, vertex: to_vertex(document))
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
  def fetch(node, field) do
    value = node.vertex._data
      |> Map.get(field)
    {:ok, value}
  end
  defp to_vertex(document) do
    doc = Map.from_struct(document)
    struct(Xarango.Vertex, doc) 
  end

      
end