defmodule Xarango.Domain.Vertex do

  alias Xarango.Vertex
  
  defmacro __using__(_options) do
    quote do
      require Xarango.Domain.Vertex
      import Xarango.Domain.Vertex
      defstruct vertex: %Xarango.Vertex{}
    end
  end
    
  defmacro collection(coll, gr, db\\nil) do
    coll = Atom.to_string(coll)
    gr = Atom.to_string(gr)
    db = db && Atom.to_string(db) || Xarango.Server.server.database
    quote do
      defp database, do: %Xarango.Database{name: unquote(db)}
      defp graph, do: %Xarango.Graph{name: unquote(gr)}
      defp vertex_collection, do: %Xarango.VertexCollection{collection: unquote(coll)}
      def create(data, options\\[]) do
        database = Xarango.Database.ensure(database)
        vc = Xarango.VertexCollection.ensure(vertex_collection, graph, database)
        vertex = Vertex.create(%Vertex{_data: data}, vc, graph, database) |> Vertex.vertex(vc, graph, database)
        struct(__MODULE__, vertex: vertex)
      end
    end
  end
  
end