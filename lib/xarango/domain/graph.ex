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
      defp _relationships, do: []
      defoverridable [_relationships: 0]
      def create, do: ensure
      def ensure do
        Database.ensure(_database)
        Graph.ensure(_graph, _database)
        Enum.each(_relationships, &ensure_collections(&1, _graph, _database))
        struct(__MODULE__, graph: Graph.graph(_graph, _database))
      end
      def destroy, do: Graph.destroy(_graph.graph, _database)
      def add(from, relationship, to, data\\nil), do: add(from, relationship, to, data, _graph, _database)
      def remove(from, relationship, to), do: remove(from, relationship, to, _graph, _database)
      def get(from, relationship, to), do: get(from, relationship, to, _database)
      def traverse(start, options\\[]), do: traverse(start, options, _graph, _database)
    end
  end
  
  defmacro relationship(from, relationship, to) do
    {relationship, from, to} = {Atom.to_string(relationship), Macro.expand(from, __CALLER__), Macro.expand(to, __CALLER__)}
    add_method = "add_#{relationship}" |> String.to_atom
    remove_method = "remove_#{relationship}" |> String.to_atom
    outbound_method = "#{relationship}_#{Xarango.Util.short_name_from(to)}" |> String.to_atom
    inbound_method = "#{Xarango.Util.short_name_from(from)}_#{relationship}" |> String.to_atom
    quote do
      @relationships %{from: unquote(from), to: unquote(to), name: unquote(relationship)}
      defp _relationships, do: @relationships
      defoverridable [_relationships: 0]
      def unquote(add_method)(%unquote(from){} = from, %unquote(to){} = to), do: add(from, unquote(relationship), to, nil)
      def unquote(add_method)(%unquote(from){} = from, %unquote(to){} = to, data), do:  add(from, unquote(relationship), to, data)
      def unquote(remove_method)(%unquote(from){} = from, %unquote(to){} = to), do: remove(from, unquote(relationship), to)
      def unquote(outbound_method)(%unquote(from){} = from), do: get(from, unquote(relationship), unquote(to))
      def unquote(inbound_method)(%unquote(to){} = to), do: get(unquote(from), unquote(relationship), to)
    end
  end
  
  def add(from_node, relationship, to_node, data, graph, database) when is_atom(relationship) do
    add(from_node, Atom.to_string(relationship), to_node, data, graph, database)
  end
  def add(from_node, relationship, to_node, data, graph, database) when is_binary(relationship) do
    from_vc = %VertexCollection{collection: Xarango.Util.name_from(from_node.__struct__) }
    from_vertex = Vertex.ensure(from_node.vertex, from_vc, graph, database)
    to_vc = %VertexCollection{collection: Xarango.Util.name_from(to_node.__struct__) }
    to_vertex = Vertex.ensure(to_node.vertex, to_vc, graph, database)
    edge = %Edge{_from: from_vertex._id, _to: to_vertex._id, _data: data}
    edge_collection = %EdgeCollection{collection: relationship }
    Edge.create(edge, edge_collection, graph, database)
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
  
  def get(from, relationship, to, database) when is_atom(relationship) do
    get(from, Atom.to_string(relationship), to, database)
  end
  def get(%{} = from_node, relationship, to, database) when is_binary(relationship) do
    edge_collection = %EdgeCollection{collection: relationship }
    Vertex.edges(from_node.vertex, edge_collection, [direction: "out"], database)
    |> Enum.map(fn edge -> 
      vertex = Vertex.vertex(%Vertex{_id: edge._to}, database)
      struct(to, %{vertex: vertex})
    end)
  end
  def get(from, relationship, %{} = to_node, database) when is_binary(relationship) do
    edge_collection = %EdgeCollection{collection: relationship }
    Vertex.edges(to_node.vertex, edge_collection, [direction: "in"], database)
    |> Enum.map(fn edge -> 
      vertex = Vertex.vertex(%Vertex{_id: edge._from}, database)
      struct(from, %{vertex: vertex})
    end)
  end
  
  def traverse(start, options, graph, database) do
    traversal = options
      |> Enum.into(%{})
      |> Map.merge(%{startVertex: start.vertex._id})
      |> Map.merge(%{graphName: graph.name})
      |> Map.merge(%{direction: "outbound"})
    struct(Traversal, traversal)  
    |> Traversal.traverse(database)
    
  end
      
  def ensure_collections(rel, graph, database) do
    {collection, from, to} = {rel[:name], rel[:from] |> Xarango.Util.name_from, rel[:to] |> Xarango.Util.name_from}
    %VertexCollection{collection: from} |> VertexCollection.ensure(graph, database)
    %VertexCollection{collection: to} |> VertexCollection.ensure(graph, database)
    %EdgeDefinition{collection: collection , from: [from], to: [to]} |> EdgeDefinition.ensure(graph, database)
  end

end

