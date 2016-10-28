defmodule Xarango.Domain.Document do
  
  alias Xarango.Document
  alias Xarango.SimpleQuery
  
  defmacro __using__(_options) do
    quote do
      require Xarango.Domain.Document
      import Xarango.Domain.Document
      
      defstruct doc: %Xarango.Document{}
      # def database, do: unquote(options[:database]) || 
      # Module.register_attribute(__MODULE__, :fields, accumulate: true)
    end
  end
  
  defmacro collection(coll, db\\nil) do
    coll = Atom.to_string(coll)
    db = db && Atom.to_string(db) || Xarango.Server.server.database
    quote do
      defp database, do: %Xarango.Database{name: unquote(db)}
      defp collection, do: %Xarango.Collection{name: unquote(coll)}
      def create(data, options\\[]) do
        Xarango.Database.ensure(database)
        Xarango.Collection.ensure(collection, database)
        doc = Document.create(%Document{_data: data}, collection, database) |> Document.document(database)
        struct(__MODULE__, doc: doc)
      end
      def one(params) do
        document = SimpleQuery.first_example(%SimpleQuery{example: params, collection: collection.name}, database)
        struct(__MODULE__, doc: document)
      end
      def replace(params, data) do
        doc = %{ one(params).doc | _data: data }
          |> Document.replace(database)
          |> Document.document(database)
        struct(__MODULE__, doc: doc)
      end
      def update(params, data) do
        doc = %{ one(params).doc | _data: data }
          |> Document.update(database)
          |> Document.document(database)
        struct(__MODULE__, doc: doc)
      end
      def destroy(params) do
        one(params).doc
        |> Document.destroy(database)
      end
      def fetch(document, field) do
        value = document.doc._data
          |> Map.get(field)
        {:ok, value}
      end
    end
  end
  
  defmacro field(name) do
    Module.put_attribute(__MODULE__, :fields, name)
  end
      
end