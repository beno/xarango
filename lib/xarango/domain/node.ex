defmodule Xarango.Domain.Node do

  alias Xarango.Vertex
  alias Xarango.SimpleQuery
  alias Xarango.Query

  defmacro __using__(options\\[]) do
    graph = options[:graph]
    collection = options[:collection]
    quote do
      use Xarango.Index
      use Xarango.Schema
      alias Xarango.Domain.Node

      defstruct vertex: %Xarango.Vertex{}
      defp _graph_module(options) do
        case options[:graph] || unquote(graph) do
          nil -> raise Xarango.Error, message: "graph not set for #{__MODULE__}"
          module -> module
        end
      end
      def _graph(options) do
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
        collection = Xarango.VertexCollection.ensure(_collection(), graph, db, indexes())
        Node.create(data, collection, _graph(options), _database(options)) |> to_node
      end
      def one(params, options\\[]), do: Node.one(params, _collection(), _graph(options), _database(options)) |> to_node
      def one?(params, options\\[]), do: Node.one?(params, _collection(), _graph(options), _database(options)) |> to_node
      def list(params, options\\[]), do: Node.list(params, options, _collection(), _graph(options), _database(options)) |> to_node
      def replace(node, data, options\\[]), do: Node.replace(node, data, _collection(), _graph(options), _database(options)) |> to_node
      def update(node, data, options\\[]), do: Node.update(node, data, _collection(), _graph(options), _database(options)) |> to_node
      def destroy(node, options\\[]), do: Node.destroy(node, _collection(), _graph(options), _database(options))
      def get(from, relationship, to, options\\[]), do: _graph_module(options).get(from, relationship, to, _graph(options), _database(options))
      def fetch(node, field) do
        case field do
          :id -> {:ok, node.vertex._id}
          "id" -> {:ok, node.vertex._id}
          value -> {:ok, get_in(node.vertex._data, List.wrap(field))}
        end
      end
      def search(field, value) do
        Query.from(_collection().collection)
        |> Query.search(field, value)
        |> Query.paginate(20)
        |> Xarango.Query.query(_database([]))
        |> Map.get(:result)
      end
      def relationships do
        _graph_module([])._relationships
        |> Enum.reduce([], fn relationship, relationships ->
          case relationship do
            %{from: __MODULE__} -> relationships ++ [relationship]
            %{to: __MODULE__} -> relationships ++ [relationship]
            _ -> relationships
          end
        end)
      end
      def to_node(nil), do: nil
      def to_node(%Xarango.QueryResult{result: vertices} = result ), do: %Xarango.QueryResult{result | result: to_node(vertices) }
      def to_node(vertices) when is_list(vertices), do: Enum.map(vertices, &to_node(&1))
      def to_node(vertex), do: struct(__MODULE__, vertex: vertex)
    end
  end

  def create(data, collection, graph, database) do
    Vertex.create(%Vertex{_data: data}, collection, graph, database)
    |> Vertex.vertex(collection, graph, database)
  end

  def one(params, collection, graph, database) do
    case params do
      %{id: id} -> Vertex.vertex(%Vertex{_id: id}, collection, graph, database)
      %{vertex: vertex} -> Vertex.vertex(vertex, collection, graph, database)
      _ -> SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.collection}, database) |> to_vertex
    end
  end
  def one?(params, collection, graph, database) do
    try do
      one(params, collection, graph, database)
    rescue
      Xarango.Error -> nil
      error -> raise error
    end
  end

  def list(params, options, collection, _graph, database) do
    case options[:cursor] do
      cursor when is_binary(cursor) ->
        Query.next(%{hasMore: true, id: cursor}, database)
      _ ->
        Query.build(%{name: collection.collection}, params, options)
        |> Query.query(database)
    end
    |> to_vertex
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

  defp to_vertex(nil) do
    nil
  end
  defp to_vertex(documents) when is_list(documents) do
    Enum.map(documents, &to_vertex(&1))
  end
  defp to_vertex(%Xarango.Document{}  = document) do
    doc = Map.from_struct(document)
    struct(Xarango.Vertex, doc)
  end
  defp to_vertex(%Xarango.QueryResult{} = result) do
    %Xarango.QueryResult{result | result: to_vertex(result.result)}
  end
  defp to_vertex(document) do
    Xarango.Document.to_document(document) |> to_vertex
  end


end
