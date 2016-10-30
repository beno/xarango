defmodule Xarango.Domain.Vertex do

  alias Xarango.Vertex
  alias Xarango.SimpleQuery
  
  
  defmacro __using__(options) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    gr = options[:graph] || raise Xarango.Error, message: "graph not set for #{__MODULE__}"
    quote do
     defstruct vertex: %Xarango.Vertex{}
      
      defp _database, do: %Xarango.Database{name: unquote(db)}
      defp _graph, do: %Xarango.Graph{name: unquote(gr)}
      defp _collection do
        coll = __MODULE__ |> Module.split |> List.last |> Macro.underscore
        %Xarango.VertexCollection{collection: coll}
      end
      def create(data) do
        Xarango.Database.ensure(_database)
        vc = Xarango.VertexCollection.ensure(_collection, _graph, _database)
        vertex = Vertex.create(%Vertex{_data: data}, vc, _graph, _database) |> Vertex.vertex(vc, _graph, _database)
        struct(__MODULE__, vertex: vertex)
      end
      def one(params) do
        document = SimpleQuery.first_example(%SimpleQuery{example: params, collection: _collection.collection}, _database)
        struct(__MODULE__, vertex: to_vertex(document))
      end
      def list(params) do
        SimpleQuery.by_example(%SimpleQuery{example: params, collection: _collection.collection}, _database)
        |> Enum.map(&struct(__MODULE__, vertex: to_vertex(&1)))
      end
      def replace(params, data) do
        vertex = %{ one(params).vertex | _data: data }
          |> Vertex.replace(_collection, _graph, _database)
          |> Vertex.vertex(_collection, _graph, _database)
        struct(__MODULE__, vertex: vertex)
      end
      def update(params, data) do
        vertex = %{ one(params).vertex | _data: data }
          |> Vertex.update(_collection, _graph, _database)
          |> Vertex.vertex(_collection, _graph, _database)
        struct(__MODULE__, vertex: vertex)
      end
      def destroy(params) do
        one(params).vertex
        |> Vertex.destroy(_collection, _graph, _database)
      end
      def fetch(vertex, field) do
        value = vertex.vertex._data
          |> Map.get(field)
        {:ok, value}
      end
      defp to_vertex(document) do
        doc = Map.from_struct(document)
        struct(Xarango.Vertex, doc) 
      end
    end
  end
      
end