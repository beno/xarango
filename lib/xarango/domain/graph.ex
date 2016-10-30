defmodule Xarango.Domain.Graph do
  
  alias Xarango.Database
  alias Xarango.Graph
  alias Xarango.Vertex
  alias Xarango.Edge
  alias Xarango.VertexCollection
  alias Xarango.EdgeDefinition
  alias Xarango.EdgeCollection
  # alias Xarango.SimpleQuery
  
  defmacro __using__(db) do
    db = is_atom(db) && Atom.to_string(db) || Xarango.Server.server.database
    quote do
      import Xarango.Domain.Graph
      defstruct graph: %Xarango.Graph{}
      Module.register_attribute __MODULE__, :relationships, accumulate: true
      defp _database, do: %Database{name: unquote(db)}
      defp _graph, do: %Graph{name: __MODULE__ |> Module.split |> List.last |> Macro.underscore }
      defp _relationships, do: []
      defoverridable [_relationships: 0]
      def create do
        database = Database.ensure(_database)
        graph = Graph.ensure(_graph, database)
        _relationships
        |> Enum.each(&add_relationship(&1, graph, database))
        struct(__MODULE__, graph: Graph.graph(graph, database))
      end
      def destroy(graph) do
        Graph.destroy(graph.graph, _database)
      end
        
    end
  end
    
  defmacro relationship(from, relationship, to) do
    from_module = Atom.to_string(from) |> Macro.camelize |> Module.concat(nil)
    to_module = Atom.to_string(to) |> Macro.camelize |> Module.concat(nil)
    add_method = "add_" |> Kernel.<>(Atom.to_string(relationship)) |> String.to_atom
    remove_method = "remove_" |> Kernel.<>(Atom.to_string(relationship)) |> String.to_atom
    method! = Atom.to_string(relationship) |> Kernel.<>("!") |> String.to_atom
    method? = Atom.to_string(relationship) |> Kernel.<>("?") |> String.to_atom
    quote do
      @relationships %{from: unquote(from), to: unquote(to), relationship: unquote(relationship)}
      defp _relationships, do: @relationships
      defoverridable [_relationships: 0]
      def unquote(add_method)(%unquote(from_module){} = from, %unquote(to_module){} = to, rel_data\\nil) do
        from_vc = %Xarango.VertexCollection{collection: unquote(from) |> Atom.to_string}
        from = Vertex.ensure(from.vertex, from_vc, _graph, _database)
        to_vc = %Xarango.VertexCollection{collection: unquote(to) |> Atom.to_string}
        to = Vertex.ensure(to.vertex, to_vc, _graph, _database)
        edge = %Edge{_from: from._id, _to: to._id, _data: rel_data}
        edge_collection = %EdgeCollection{collection: unquote(relationship) |> Atom.to_string }
        Edge.create(edge, edge_collection, _graph, _database)
      end
      def unquote(remove_method)(%unquote(from_module){} = from, %unquote(to_module){} = to) do
        edge = %Edge{_from: from.vertex._id, _to: to.vertex._id}
        edge_collection = %EdgeCollection{collection: unquote(relationship) |> Atom.to_string }
        Edge.destroy(edge, edge_collection, _graph, _database)
      end
      def unquote(method!)(%unquote(from_module){} = from) do
        edge_collection = %EdgeCollection{collection: unquote(relationship) |> Atom.to_string }
        Vertex.edges(from.vertex, edge_collection, _database, direction: "out")
        |> Enum.map(fn edge -> 
          to_vc = %Xarango.VertexCollection{collection: unquote(to) |> Atom.to_string}
          key = String.replace(edge._to,~r{[^\/]*/(.*)}, "\\1")
          vertex = Vertex.vertex(%Vertex{_key: key}, to_vc, _graph, _database)
          struct(unquote(to_module), %{vertex: vertex})
        end)
      end
      def unquote(method?)(%unquote(to_module){} = to) do
        edge_collection = %EdgeCollection{collection: unquote(relationship) |> Atom.to_string }
        Vertex.edges(to.vertex, edge_collection, _database, direction: "in")
        |> Enum.map(fn edge -> 
          from_vc = %Xarango.VertexCollection{collection: unquote(from) |> Atom.to_string}
          key = String.replace(edge._from,~r{[^\/]*/(.*)}, "\\1")
          vertex = Vertex.vertex(%Vertex{_key: key}, from_vc, _graph, _database)
          struct(unquote(from_module), %{vertex: vertex})
        end)
      end


    end
  end
  
  def add_relationship(rel, graph, database) do
    {collection, from, to} = {Atom.to_string(rel[:relationship]), Atom.to_string(rel[:from]), Atom.to_string(rel[:to])}
    %VertexCollection{collection: from} |> VertexCollection.ensure(graph, database)
    %VertexCollection{collection: to} |> VertexCollection.ensure(graph, database)
    %EdgeDefinition{collection: collection , from: [from], to: [to]} |> EdgeDefinition.ensure(graph, database)
  end

  
end

