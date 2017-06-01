defmodule Xarango.Domain.Document do
  
  alias Xarango.Document
  alias Xarango.SimpleQuery
  
  defmacro __using__(options) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    coll = options[:collection] && Atom.to_string(options[:collection])

    quote do
      import Xarango.Domain.Document
      defstruct doc: %Xarango.Document{}
      def _database, do: %Xarango.Database{name: unquote(db)}
      defp _collection, do: %Xarango.Collection{name: unquote(coll) || Xarango.Util.name_from(__MODULE__)}
      def create(data, options\\[]) do
        Xarango.Database.ensure(_database())
        Xarango.Collection.ensure(_collection(), _database())
        Document.create(%Document{_data: data}, _collection(), _database())
        |> Document.document(_database())
        |> to_document
      end
      def one(params) do
        SimpleQuery.first_example(%SimpleQuery{example: params, collection: _collection().name}, _database())
        |> to_document
      end
      def list(params) do
        SimpleQuery.by_example(%SimpleQuery{example: params, collection: _collection().name}, _database())
        |> Enum.map(&struct(__MODULE__, doc: &1))
      end
      def replace(document, data) do
        %{ document.doc | _data: data }
        |> Document.replace(_database())
        |> Document.document(_database())
        |> to_document
      end
      def update(document, data) do
        %{ document.doc | _data: data }
        |> Document.update(_database())
        |> Document.document(_database())
        |> to_document
      end
      def destroy(document) do
        document.doc
        |> Document.destroy(_database())
      end
      def fetch(document, field) do
        value = document.doc._data
          |> Map.get(field)
        {:ok, value}
      end
      
      defp to_document(data) do
        struct(__MODULE__, doc: data)
      end

    end
  end
  
      
end