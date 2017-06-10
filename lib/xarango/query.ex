defmodule Xarango.Query do

  defstruct [:query, :count, :ttl, :batchSize, :cache, :bindVars, :options]

  alias Xarango.Query
  alias Xarango.AQL
  import Xarango.Client
  use Xarango.URI, prefix: "cursor"

  def query(query) when is_binary(query) do
    query(%Query{query: query})
  end

  def query(query, database\\nil)
  def query(%Query{query: %AQL{}} = query, database) do
    url("", database)
    |> post(%Query{query | query: AQL.to_aql(query.query)})
    |> to_result
  end
  def query(query, database) do
    url("", database)
    |> post(query)
    |> to_result
  end

  def next(result, database\\nil) do
    result.hasMore &&
    case result.id do
      nil -> false
      id ->
        url(id, database)
        |> put(%{})
        |> to_result
    end
  end

  def explain(query, database\\nil) do
    Xarango.URI.path("explain", database)
    |> Xarango.Client._url([])
    |> post(query)
    |> to_explanation
  end

  defp to_result(data) do
    struct(Xarango.QueryResult, data)
  end

  defp to_explanation(data) do
    struct(Xarango.Explanation, data)
  end
  
  def from(collection) do
    %Xarango.Query{query: AQL.from(collection)}
  end

  def filter(query, nil), do: query
  def filter(query, filter) when is_map(filter) do
    where(query, Map.to_list(filter))
  end
  def filter(query, filter) do
    %Xarango.Query{query | query: AQL.filter(query.query, filter) }
  end
  defdelegate where(query, filters), to: __MODULE__, as: :filter
  
  def sort(query, nil), do: query
  def sort(query, sort) do
    %Xarango.Query{query | query: AQL.sort(query.query, sort) }
  end
  
  def limit(query, nil), do: query
  def limit(query, limit) do
    %Xarango.Query{query | query: AQL.limit(query.query, limit) }
  end
  
  def paginate(query, nil), do: query
  def paginate(query, page_length) do
    %Xarango.Query{query | batchSize: page_length }
  end
  
  def build(collection, filter, options) do
    from(collection)
    |> filter(filter)
    |> sort(options[:sort])
    |> limit(options[:limit])
    |> paginate(options[:per_page])
  end

end

defmodule Xarango.QueryResult do

  defstruct [:id, :hasMore, :extra, :error, :result, :code, :count, :cached]

end

defmodule Xarango.Explanation do

  defstruct [:plans, :warnings, :stats, :cacheable, :error, :code]

end

