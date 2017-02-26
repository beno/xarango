defmodule Xarango.Query do

  defstruct [:query, :count, :ttl, :batchSize, :cache, :bindVars, :options]

  alias Xarango.Query
  import Xarango.Client
  use Xarango.URI, prefix: "cursor"

  def query(query) when is_binary(query) do
    query(%Query{query: query})
  end

  def query(query, database\\nil) do
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

end

defmodule Xarango.QueryResult do

  defstruct [:id, :hasMore, :extra, :error, :result, :code, :count, :cached]

end

defmodule Xarango.Explanation do

  defstruct [:plans, :warnings, :stats, :cacheable, :error, :code]

end
