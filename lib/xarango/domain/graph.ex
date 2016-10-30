defmodule Xarango.Domain.Graph do
  
  alias Xarango.Database
  alias Xarango.Graph
  alias Xarango.Vertex
  alias Xarango.Edge
  alias Xarango.VertexCollection
  alias Xarango.EdgeDefinition
  alias Xarango.EdgeCollection
  alias Xarango.SimpleQuery
  
  defmacro __using__(options\\[]) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    gr = options[:graph] && Atom.to_string(options[:graph])
    quote do
      require Xarango.Domain.Graph
      import Xarango.Domain.Graph
      defstruct graph: %Xarango.Graph{}
      Module.register_attribute __MODULE__, :relationships, accumulate: true
      defp _database, do: %Database{name: unquote(db)}
      defp _graph, do: %Graph{name: unquote(gr) || Xarango.Util.name_from(__MODULE__) }
      defp _relationships, do: []
      defoverridable [_relationships: 0]
      def create do
        Database.ensure(_database)
        Graph.ensure(_graph, _database)
        _relationships
        |> Enum.each(&add_relationship(&1, _graph, _database))
        struct(__MODULE__, graph: Graph.graph(_graph, _database))
      end
      def destroy(graph) do
        Graph.destroy(graph.graph, _database)
      end
        
    end
  end
    
  defmacro relationship(from, relationship, to) do
    {relationship, from, to} = {Atom.to_string(relationship), Atom.to_string(from), Atom.to_string(to)}
    from_module = from |> Macro.camelize |> Module.concat(nil)
    to_module = to |> Macro.camelize |> Module.concat(nil)
    add_method = "add_#{relationship}" |> String.to_atom
    remove_method = "remove_#{relationship}" |> String.to_atom
    outbound_method = "#{relationship}_#{to}" |> String.to_atom
    inbound_method = "#{from}_#{relationship}" |> String.to_atom
    quote do
      @relationships %{from: unquote(from), to: unquote(to), relationship: unquote(relationship)}
      defp _relationships, do: @relationships
      defoverridable [_relationships: 0]
      def unquote(add_method)(%unquote(from_module){} = from_node, %unquote(to_module){} = to_node, rel_data\\nil) do
        from_vc = %Xarango.VertexCollection{collection: unquote(from) }
        from_vertex = Vertex.ensure(from_node.vertex, from_vc, _graph, _database)
        to_vc = %Xarango.VertexCollection{collection: unquote(to) }
        to_vertex = Vertex.ensure(to_node.vertex, to_vc, _graph, _database)
        edge = %Edge{_from: from_vertex._id, _to: to_vertex._id, _data: rel_data}
        edge_collection = %EdgeCollection{collection: unquote(relationship) }
        Edge.create(edge, edge_collection, _graph, _database)
      end
      def unquote(remove_method)(%unquote(from_module){} = from_node, %unquote(to_module){} = to_node) do
        example = %{_from: from_node.vertex._id, _to: to_node.vertex._id}
        edge_collection = %EdgeCollection{collection: unquote(relationship) }
        %SimpleQuery{example: example, collection: edge_collection.collection}
        |> SimpleQuery.by_example(_database)
        |> Enum.map(&Edge.destroy(&1, edge_collection, _graph, _database))        
      end
      def unquote(outbound_method)(%unquote(from_module){} = from_node) do
        edge_collection = %EdgeCollection{collection: unquote(relationship) }
        Vertex.edges(from_node.vertex, edge_collection, _database, direction: "out")
        |> Enum.map(fn edge -> 
          to_vc = %Xarango.VertexCollection{collection: unquote(to) }
          key = String.replace(edge._to,~r{[^\/]*/(.*)}, "\\1")
          vertex = Vertex.vertex(%Vertex{_key: key}, to_vc, _graph, _database)
          struct(unquote(to_module), %{vertex: vertex})
        end)
      end
      def unquote(inbound_method)(%unquote(to_module){} = to_node) do
        edge_collection = %EdgeCollection{collection: unquote(relationship) }
        Vertex.edges(to_node.vertex, edge_collection, _database, direction: "in")
        |> Enum.map(fn edge -> 
          from_vc = %Xarango.VertexCollection{collection: unquote(from)}
          key = String.replace(edge._from,~r{[^\/]*/(.*)}, "\\1")
          vertex = Vertex.vertex(%Vertex{_key: key}, from_vc, _graph, _database)
          struct(unquote(from_module), %{vertex: vertex})
        end)
      end
    end
  end
  
  def add_relationship(rel, graph, database) do
    {collection, from, to} = {rel[:relationship], rel[:from], rel[:to]}
    %VertexCollection{collection: from} |> VertexCollection.ensure(graph, database)
    %VertexCollection{collection: to} |> VertexCollection.ensure(graph, database)
    %EdgeDefinition{collection: collection , from: [from], to: [to]} |> EdgeDefinition.ensure(graph, database)
  end

  
end

