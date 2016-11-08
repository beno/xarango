defmodule Xarango.Domain.Node do

  alias Xarango.Vertex
  alias Xarango.SimpleQuery
  
  
  #GET DATABASE FROM GRAPH!!
  defmacro __using__(options\\[]) do
    database = options[:db] && Atom.to_string(options[:db])
    graph = options[:graph]
    quote do
      alias Xarango.Domain.Node
      defstruct vertex: %Xarango.Vertex{}
      defp _graph_module(options\\[]) do
        case options[:graph] do
          nil -> unquote(graph)
          graph -> graph
        end
      end
      defp _graph(options) when is_list(options) do
        case _graph_module(options) do
          nil -> raise Xarango.Error, message: "graph not set for #{__MODULE__}"
          graph -> %Xarango.Graph{name: Xarango.Util.name_from(graph)}
        end
      end
      defp _database(options) when is_list(options) do
        case options[:db] do
          db when is_binary(db) -> _database(db)
          nil -> (unquote(database) || apply(_graph_module(options), :_database, [])) |> _database
          _ -> raise Xarango.Error, message: "invalid database for #{__MODULE__}"
        end
      end
      defp _database(name) do
        case name do
          nil -> raise Xarango.Error, message: "database not set for #{__MODULE__}"
          %Xarango.Database{} = db -> db
          name when is_binary(name)-> %Xarango.Database{name: name}
        end
      end
      defp _collection, do: %Xarango.VertexCollection{collection: Xarango.Util.name_from(__MODULE__)}
      def create(data, options\\[]), do: Node.create(data, _collection, _graph(options), _database(options)) |> to_node
      def one(params, options\\[]), do: Node.one(params, _collection, _graph(options), _database(options)) |> to_node
      def list(params, options\\[]), do: Node.list(params, _collection, _graph(options), _database(options)) |> to_nodes
      def replace(node, data, options\\[]), do: Node.replace(node, data, _collection, _graph(options), _database(options)) |> to_node
      def update(node, data, options\\[]), do: Node.update(node, data, _collection, _graph(options), _database(options)) |> to_node
      def destroy(node, options\\[]), do: Node.destroy(node, _collection, _graph(options), _database(options))
      def fetch(node, field) do
        value = node.vertex._data |> Map.get(field)
        {:ok, value}
      end
      defp to_node(vertex), do: struct(__MODULE__, vertex: vertex)
      defp to_nodes(vertices), do: vertices |> Enum.map(&struct(__MODULE__, vertex: &1))
    end
  end
  
  def create(data, collection, graph, database) do
    Xarango.Database.ensure(database)
    Xarango.Graph.ensure(graph)
    vc = Xarango.VertexCollection.ensure(collection, graph, database)
    Vertex.create(%Vertex{_data: data}, vc, graph, database)
    |> Vertex.vertex(vc, graph, database)
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