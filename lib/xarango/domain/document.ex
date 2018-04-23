defmodule Xarango.Domain.Document do

  alias Xarango.Document
  alias Xarango.SimpleQuery
  alias Xarango.Query

  defmacro __using__(options) do
    db = options[:db] && Atom.to_string(options[:db]) || Xarango.Server.server.database
    coll = options[:collection] && Atom.to_string(options[:collection])

    quote do
      use Xarango.Index
      use Xarango.Schema

      defstruct doc: %Xarango.Document{}
      def _database, do: %Xarango.Database{name: unquote(db)}
      defp _collection, do: %Xarango.Collection{name: unquote(coll) || Xarango.Util.name_from(__MODULE__)}
      def create(data, options\\[]) do
        options = Keyword.put(options, :returnNew, true)
        Xarango.Database.ensure(_database())
        Xarango.Collection.ensure(_collection(), _database(), indexes())
        Document.create(%Document{_data: data}, _collection(), _database(), options)
        |> to_document
      end
      def one(params) do
        SimpleQuery.first_example(%SimpleQuery{example: params, collection: _collection().name}, _database())
        |> to_document
      end
      def one?(params) do
        try do
          one(params)
        rescue
          Xarango.Error -> nil
          error -> raise error
        end
      end
      def list(params, options\\[]) do
        case options[:cursor] do
          cursor when is_binary(cursor) ->
            Query.next(%{hasMore: true, id: cursor}, _database())
          _ ->
            Query.build(_collection(), params, options)
            |> Query.query(_database())
        end
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

      @doc """
        ## Wthin geo search in collection

        Make sure you have a geo index on collection module

        ```
        defmodule Station do
          index :geo, :location
        end
        ```

        First argument it's a list with lat & lon,
        Second argument represent the radius within arango will search
        Third argument define a new column with distance in meters (filled by arango)

        `Station.within({47.632014, -122.207210}, 100, :distance)`
      """
      def within([latitude, longitude], radius \\ 0, column \\ :distance) do
        %Xarango.Query{query: "FOR doc IN WITHIN(#{_collection().name}, #{latitude}, #{longitude}, #{radius}, \"#{Atom.to_string(column)}\") RETURN doc", batchSize: 3}
        |> Xarango.Query.query(_database())
        |> Map.get(:result)
        |> to_document
      end

      @doc """
        ## Near geo search in collection

        Make sure you have a geo index on collection module

        ```
        defmodule Station do
          index :geo, :location
        end
        ```
        First argument it's a list with lat & lon,
        Second argument limit results to only first n results
        Third argument define a new column with distance in meters (filled by arango)

        `Station.near({47.632014, -122.207210}, 10, :distance)`
      """
      def near([latitude, longitude], limit \\ 0, column \\ :distance) do
        %Xarango.Query{query: "FOR doc IN NEAR(#{_collection().name}, #{latitude}, #{longitude}, #{limit}, \"#{Atom.to_string(column)}\") RETURN doc", batchSize: 3}
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
      defp to_document(%Xarango.QueryResult{} = result) do
        %Xarango.QueryResult{result | result: to_document(result.result)}
      end
      defp to_document(%Xarango.Document{} = doc) do
        struct(__MODULE__, doc: doc)
      end
      defp to_document(doc) do
        struct(__MODULE__, doc: Document.to_document(doc))
      end
    end
  end
end
