defmodule Xarango.Domain.Node do

  alias Xarango.Vertex
  alias Xarango.SimpleQuery
  alias Xarango.Index
  
  defmacro index(type, field) do
    quote do
      @indexes %Index{type: Atom.to_string(unquote(type)), fields: [Atom.to_string(unquote(field))]}
      defp indexes, do: @indexes
      defoverridable [indexes: 0]
    end
  end
  
  defmacro __using__(options\\[]) do
    graph = options[:graph]
    collection = options[:collection]
    quote do
      alias Xarango.Domain.Node
      import Xarango.Domain.Node, only: [index: 2]
      defstruct vertex: %Xarango.Vertex{}
      Module.register_attribute __MODULE__, :indexes, accumulate: true
      defp indexes, do: []
      defoverridable [indexes: 0]
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
      def _collection do
        collection = case unquote(collection) do
          nil -> Xarango.Util.name_from(__MODULE__)
          coll when is_atom(coll) -> Atom.to_string(coll)
          coll when is_binary(coll) -> coll
        end
        %Xarango.VertexCollection{collection: collection}
      end
      def create(data, options\\[]) do
        db = _database(options)
        graph = _graph(options)
        apply(_graph_module(options), :ensure, [])
        Node.create(data, _collection(), _graph(options), _database(options)) |> to_node
      end
      def one(params, options\\[]), do: Node.one(params, _collection(), _graph(options), _database(options)) |> to_node
      def list(params, options\\[]), do: Node.list(params, _collection(), _graph(options), _database(options)) |> to_nodes
      def replace(node, data, options\\[]), do: Node.replace(node, data, _collection(), _graph(options), _database(options)) |> to_node
      def update(node, data, options\\[]), do: Node.update(node, data, _collection(), _graph(options), _database(options)) |> to_node
      def destroy(node, options\\[]), do: Node.destroy(node, _collection(), _graph(options), _database(options))
      def fetch(node, field) do
        case field do
          :id -> {:ok, node.vertex._id}
          "id" -> {:ok, node.vertex._id}
          value -> {:ok, get_in(node.vertex._data, List.wrap(field))}
        end
      end
      defp to_node(vertex), do: struct(__MODULE__, vertex: vertex)
      defp to_nodes(vertices), do: vertices |> Enum.map(&struct(__MODULE__, vertex: &1))
      def search(field, value) do
        %Xarango.Query{query: "FOR doc IN FULLTEXT(#{_collection().collection}, \"#{field}\", \"prefix:#{value}\") RETURN doc", batchSize: 3}
        |> Xarango.Query.query(_database([]))
        |> Map.get(:result)
      end
    end
  end

  def create(data, collection, graph, database) do
    Vertex.create(%Vertex{_data: data}, collection, graph, database)
    |> Vertex.vertex(collection, graph, database)
  end

  def one(params, collection, edges, _graph, database) when is_list(edges) do
    SimpleQuery.by_example(%SimpleQuery{example: params, collection: collection.collection}, database) |> to_vertex
  end
  def one(params, collection, graph, database) do
    case params do
      %{id: id} -> Vertex.vertex(%Vertex{_id: id}, collection, graph, database)
      %{vertex: vertex} -> Vertex.vertex(vertex, collection, graph, database)
      _ -> SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.collection}, database) |> to_vertex
    end
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
