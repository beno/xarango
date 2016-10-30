# defmodule Xarango.Domain.Edge do
#   
#   alias Xarango.Edge
#   alias Xarango.SimpleQuery
# 
#   defmacro __using__(_options) do
#     quote do
#       import Xarango.Domain.Edge
#       defstruct doc: %Xarango.Edge{}
#     end
#   end
#   
#   defmacro collection(coll, gr, db\\nil) do
#     db = db && Atom.to_string(db) || Xarango.Server.server.database
#     quote do
#       defp database, do: %Xarango.Database{name: unquote(db)}
#       defp graph, do: %Xarango.Graph{name: unquote(gr)}
#       defp collection, do: %Xarango.VertexCollection{collection: unquote(coll)}
#       def create(data, options\\[]) do
#         database = Xarango.Database.ensure(database)
#         vc = Xarango.EdgeCollection.ensure(collection, graph, database)
#         vertex = Vertex.create(%Vertex{_data: data}, vc, graph, database) |> Vertex.vertex(vc, graph, database)
#         struct(__MODULE__, vertex: vertex)
#       end
#       def one(params) do
#         document = SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.collection}, database)
#         struct(__MODULE__, vertex: to_vertex(document))
#       end
#       def list(params) do
#         SimpleQuery.by_example(%SimpleQuery{example: params, collection: collection.collection}, database)
#         |> Enum.map(&struct(__MODULE__, vertex: to_vertex(&1)))
#       end
#       def replace(params, data) do
#         vertex = %{ one(params).vertex | _data: data }
#           |> Vertex.replace(collection, graph, database)
#           |> Vertex.vertex(collection, graph, database)
#         struct(__MODULE__, vertex: vertex)
#       end
#       def update(params, data) do
#         vertex = %{ one(params).vertex | _data: data }
#           |> Vertex.update(collection, graph, database)
#           |> Vertex.vertex(collection, graph, database)
#         struct(__MODULE__, vertex: vertex)
#       end
#       def destroy(params) do
#         one(params).vertex
#         |> Vertex.destroy(collection, graph, database)
#       end
#       def fetch(vertex, field) do
#         value = vertex.vertex._data
#           |> Map.get(field)
#         {:ok, value}
#       end
#       defp to_vertex(document) do
#         doc = Map.from_struct(document)
#         struct(Xarango.Vertex, doc) 
#       end
#     end
#   end
# 
#   
# end