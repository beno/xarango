defmodule Xarango.Domain.Graph do

  alias Xarango.Database
  alias Xarango.Graph
  alias Xarango.Vertex
  alias Xarango.Edge
  alias Xarango.VertexCollection
  alias Xarango.EdgeDefinition
  alias Xarango.EdgeCollection
  alias Xarango.SimpleQuery
  alias Xarango.Traversal
  alias Xarango.Util

  defmacro __using__(options\\[]) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    gr = options[:graph] && Xarango.Util.name_from(options[:graph])
    quote do
      require Xarango.Domain.Graph
      import Xarango.Domain.Graph
      defstruct graph: %Xarango.Graph{}
      Module.register_attribute __MODULE__, :relationships, accumulate: true
      def _database, do: %Database{name: unquote(db)}
      defp _graph, do: %Graph{name: unquote(gr) || Xarango.Util.name_from(__MODULE__) }
      def create, do: ensure()
      def ensure do
        Database.ensure(_database())
        Graph.ensure(_graph(), _database())
        Enum.each(_relationships(), &ensure_collections(&1, _graph(), _database()))
        struct(__MODULE__, graph: Graph.graph(_graph(), _database()))
      end
      def destroy, do: Graph.destroy(_graph().graph, _database())
      def add(from, relationship, to, data\\nil), do: add(from, relationship, to, data, _graph(), _database())
      def ensure(from, relationship, to, data\\nil), do: ensure(from, relationship, to, data, _graph(), _database())
      def remove(from, relationship, to), do: remove(from, relationship, to, _graph(), _database())
      def get(from, relationship, to), do: get(from, relationship, to, _graph(), _database())
      def traverse(start, options\\[]), do: traverse(start, options, _graph(), _database())
      @before_compile Xarango.Domain.Graph
    end
  end

  defmacro relationship(from, relationship, to) do
    {relationship, from, to} = {Atom.to_string(relationship), Macro.expand(from, __CALLER__), Macro.expand(to, __CALLER__)}
    quote do
      relationship = %{from: unquote(from), to: unquote(to), name: unquote(relationship)}
      unless Enum.member?(@relationships, relationship), do: @relationships relationship
    end
  end

  defmacro __before_compile__(env) do
    relationships = Module.get_attribute(env.module, :relationships)
    methods = Enum.map relationships, fn %{from: from, to: to, name: relationship} ->
      add_method = "add_#{relationship}" |> String.to_atom
      ensure_method = "ensure_#{relationship}" |> String.to_atom
      remove_method = "remove_#{relationship}" |> String.to_atom
      inbound_method = "#{relationship}_#{Util.short_name_from(to)}" |> String.to_atom
      outbound_method = "#{Util.short_name_from(from)}_#{relationship}" |> String.to_atom
      quote do
        def unquote(add_method)(%unquote(from){} = from, %unquote(to){} = to), do: unquote(add_method)(from, to, nil)
        def unquote(add_method)(%unquote(from){} = from, %unquote(to){} = to, data), do:  add(from, unquote(relationship), to, data)
        def unquote(ensure_method)(%unquote(from){} = from, %unquote(to){} = to), do: unquote(ensure_method)(from, to, nil)
        def unquote(ensure_method)(%unquote(from){} = from, %unquote(to){} = to, data), do: ensure(from, unquote(relationship), to, data)
        def unquote(remove_method)(%unquote(from){} = from, %unquote(to){} = to), do: remove(from, unquote(relationship), to)
        def unquote(inbound_method)(%unquote(from){} = from), do: get(from, unquote(relationship), unquote(to))
        def unquote(outbound_method)(%unquote(to){} = to), do: get(unquote(from), unquote(relationship), to)
      end
    end
    quote do
      defp _relationships, do: @relationships
      unquote(methods)
    end
  end

  def add(from_node, relationship, to_node, data, graph, database) when is_atom(relationship) do
    add(from_node, Atom.to_string(relationship), to_node, data, graph, database)
  end
  def add(from_node, relationship, to_node, data, graph, database) when is_binary(relationship) do
    from_vertex = Vertex.ensure(from_node.vertex, apply(from_node.__struct__, :_collection, []), graph, database)
    to_vertex = Vertex.ensure(to_node.vertex, apply(to_node.__struct__, :_collection, []), graph, database)
    edge = %Edge{_from: from_vertex._id, _to: to_vertex._id, _data: data}
    edge_collection = %EdgeCollection{collection: relationship }
    Edge.create(edge, edge_collection, graph, database)
  end

  def ensure(from, relationship, to, data, graph, database) do
    case get(from, relationship, to, graph, database) do
      [] -> add(from, relationship, to, data, graph, database)
      [edge] -> edge
    end
  end

  def remove(from_node, relationship, to_node, graph, database) when is_atom(relationship) do
    remove(from_node, Atom.to_string(relationship), to_node, graph, database)
  end
  def remove(from_node, relationship, to_node, graph, database) when is_binary(relationship) do
    example = %{_from: from_node.vertex._id, _to: to_node.vertex._id}
    edge_collection = %EdgeCollection{collection: relationship }
    %SimpleQuery{example: example, collection: edge_collection.collection}
    |> SimpleQuery.by_example(database)
    |> Enum.map(&Edge.destroy(&1, edge_collection, graph, database))
  end

  def get(from, relationship, to, graph, database) when is_atom(relationship) do
    get(from, Atom.to_string(relationship), to, graph, database)
  end
  def get(%{} = from_node, relationship, %{} = to_node, _graph, database) when is_binary(relationship) do
    edge_collection = %EdgeCollection{collection: relationship }
    %SimpleQuery{example: %{_from: from_node[:id], _to: to_node[:id]}, collection: edge_collection.collection}
    |> SimpleQuery.by_example(database)
  end
  def get(%{} = from_node, relationship, to, graph, database) when is_binary(relationship) do
    traverse(from_node, [edgeCollection: relationship, direction: "outbound"], graph, database)
    |> Xarango.TraversalResult.vertices_to |> to.to_node
  end
  def get(from, relationship, %{} = to_node, graph, database) when is_binary(relationship) do
    traverse(to_node, [edgeCollection: relationship, direction: "inbound"], graph, database)
    |> Xarango.TraversalResult.vertices_from |> from.to_node
  end

  def traverse(start, options, graph, database) do
    traversal = options
      |> Enum.into(%{})
      |> Map.merge(%{direction: "outbound"}, fn _k, v1, _v2 -> v1 end)
      |> Map.merge(%{startVertex: start.vertex._id})
      |> Map.merge(%{graphName: graph.name})
      |> Map.merge(%{uniqueness: %{vertices: "global", edges: "global"}})
    struct(Traversal, traversal)
    |> Traversal.traverse(database)
  end

  def ensure_collections(rel, graph, database) do
    {collection, from, to} = {rel[:name], apply(rel[:from], :_collection, []), apply(rel[:to], :_collection, [])}
    from |> VertexCollection.ensure(graph, database)
    to |> VertexCollection.ensure(graph, database)
    %EdgeDefinition{collection: collection , from: [from.collection], to: [to.collection]} |> EdgeDefinition.ensure(graph, database)
  end

end
