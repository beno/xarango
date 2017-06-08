defmodule Xarango.Domain.Document do

  alias Xarango.Document
  alias Xarango.SimpleQuery
  alias Xarango.Index
  
  defmacro index(type, field) do
    quote do
      @indexes %Index{type: Atom.to_string(unquote(type)), fields: [Atom.to_string(unquote(field))]}
      defp indexes, do: @indexes
      defoverridable [indexes: 0]
    end
  end
  
  defmacro __using__(options) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    coll = options[:collection] && Atom.to_string(options[:collection])

    quote do
      import Xarango.Domain.Document
      defstruct doc: %Xarango.Document{}
      Module.register_attribute __MODULE__, :indexes, accumulate: true
      defp indexes, do: @indexes
      defoverridable [indexes: 0]
      def _database, do: %Xarango.Database{name: unquote(db)}
      defp _collection, do: %Xarango.Collection{name: unquote(coll) || Xarango.Util.name_from(__MODULE__)}
      def create(data, options\\[]) do
        Xarango.Database.ensure(_database())
        Xarango.Collection.ensure(_collection(), _database(), indexes())
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
        |> to_document
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
      
      def search(field, value) do
        %Xarango.Query{query: "FOR doc IN FULLTEXT(#{_collection().name}, \"#{field}\", \"prefix:#{value}\") RETURN doc", batchSize: 3}
        |> Xarango.Query.query(_database())
        |> Map.get(:result)
        |> to_document
      end

      def fetch(document, field) do
        case field do
          :id -> {:ok, document.doc._id}
          "id" -> {:ok, document.doc._id}
          value -> {:ok, get_in(document.doc._data, List.wrap(field))}
        end
      end

      defp to_document(docs) when is_list(docs) do
        docs |> Enum.map(&to_document(&1))
      end
      defp to_document(doc) do
        struct(__MODULE__, doc: doc)
      end
      
    end
  end


end
