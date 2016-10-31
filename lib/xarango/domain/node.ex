defmodule Xarango.Domain.Node do

  alias Xarango.Vertex
  alias Xarango.SimpleQuery
  
  
  defmacro __using__(options) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    gr = options[:graph]
    quote do
      defstruct vertex: %Xarango.Vertex{}
      defp _database, do: %Xarango.Database{name: unquote(db)}
      defp _graph(nil) do
        case unquote(gr) do
          nil -> raise Xarango.Error, message: "graph not set for #{__MODULE__}"
          graph -> %Xarango.Graph{name: Atom.to_string(graph)}
        end
      end
      defp _graph(name), do: %Xarango.Graph{name: Atom.to_string(name)}
      defp _collection do
        %Xarango.VertexCollection{collection: Xarango.Util.name_from(__MODULE__)}
      end
      def create(data, graph\\nil) do
        Xarango.Database.ensure(_database)
        vc = Xarango.VertexCollection.ensure(_collection, _graph(graph), _database)
        vertex = Vertex.create(%Vertex{_data: data}, vc, _graph(graph), _database) |> Vertex.vertex(vc, _graph(graph), _database)
        struct(__MODULE__, vertex: vertex)
      end
      def one(params, _gr\\nil) do
        document = SimpleQuery.first_example(%SimpleQuery{example: params, collection: _collection.collection}, _database)
        struct(__MODULE__, vertex: to_vertex(document))
      end
      def list(params, _gr\\nil) do
        SimpleQuery.by_example(%SimpleQuery{example: params, collection: _collection.collection}, _database)
        |> Enum.map(&struct(__MODULE__, vertex: to_vertex(&1)))
      end
      def replace(vertex, data, graph\\nil) do
        vertex = %{ vertex.vertex | _data: data }
          |> Vertex.replace(_collection, _graph(graph), _database)
          |> Vertex.vertex(_collection, _graph(graph), _database)
        struct(__MODULE__, vertex: vertex)
      end
      def update(vertex, data, graph\\nil) do
        vertex = %{ vertex.vertex | _data: data }
          |> Vertex.update(_collection, _graph(graph), _database)
          |> Vertex.vertex(_collection, _graph(graph), _database)
        struct(__MODULE__, vertex: vertex)
      end
      def destroy(vertex, graph\\nil) do
        vertex.vertex
        |> Vertex.destroy(_collection, _graph(graph), _database)
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