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
  def query(%AQL{} = query, database) do
    query(%Query{query: query}, database)
  end
  def query(%Query{query: %AQL{}} = query, database) do
    query(%Query{query | query: AQL.to_aql(query.query)}, database)
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
  def sort(query, sort), do: sort(query, sort, :asc)
  def sort(query, nil, nil), do: query
  def sort(query, sort, nil), do: sort(query, sort, :asc)
  def sort(query, sort, dir) do
    %Xarango.Query{query | query: AQL.sort(query.query, sort, dir) }
  end


  def limit(query, nil), do: query
  def limit(query, limit) do
    %Xarango.Query{query | query: AQL.limit(query.query, limit) }
  end

  def paginate(query, nil), do: query
  def paginate(query, page_length, page\\nil)
  def paginate(query, page_length, nil) do
    %Xarango.Query{query | batchSize: page_length, count: true }
  end
  def paginate(query, page_length, page) do
    %Xarango.Query{query | query: AQL.limit(query.query, page_length, page_length*(page-1)) }
  end

  def search(query, field, value) do
    %Xarango.Query{query | query: AQL.fulltext(query.query, field, value) }
  end


  def build(collection, filter, options) do
    from(collection)
    |> filter(filter)
    |> sort(options[:sort], options[:dir])
    |> limit(options[:limit])
    |> paginate(options[:per_page], options[:page])
  end

end

defmodule Xarango.QueryResult do

  defstruct [:id, :hasMore, :extra, :error, :result, :code, :count, :cached]

  def to_vertex(query_result) do
    query_result.result
    |> Xarango.Vertex.to_vertex
  end

  def to_edge(query_result) do
    query_result.result
    |> Enum.reduce([], fn [_v, e], edges ->
      case e do
        nil -> edges
        edge -> edges ++ [edge]
      end
    end)
    |> Xarango.Edge.to_edge
  end


end

defmodule Xarango.Explanation do

  defstruct [:plans, :warnings, :stats, :cacheable, :error, :code]

end

