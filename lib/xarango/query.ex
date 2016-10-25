defmodule Xarango.Query do
  
  defstruct [:query, :count, :ttl, :batchSize, :cache, :bindVars, :options]
  
  alias Xarango.Client
  alias Xarango.Query
  
  def query(query) when is_binary(query) do
    query(%Query{query: query})
  end

  def query(query) do
    url
    |> Client.post(query)
    |> to_result
  end
  
  def next(result) do
    result.hasMore &&
    case result.id do
      nil -> false
      id ->
        url(id)
        |> Client.put(%{})
        |> to_result
    end
  end
  
  def explain(query) do
    Xarango.Connection.url("/_api/explain")
    |> Client.post(query)
    |> to_explanation
  end
  
  defp to_result(data) do
    struct(Xarango.QueryResult, data)
  end
  
  defp to_explanation(data) do
    struct(Xarango.Explanation, data)
  end

    
  
  defp url(path\\"", options\\[]) do
    Xarango.Connection.url("/_api/cursor/#{path}", options)
  end
  
  
end

defmodule Xarango.QueryResult do
  
  defstruct [:id, :hasMore, :extra, :error, :result, :code, :count, :cached]

end

defmodule Xarango.Explanation do

  defstruct [:plans, :warnings, :stats, :cacheable, :error, :code]

end
