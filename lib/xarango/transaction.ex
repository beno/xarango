defmodule Xarango.Transaction do

  defstruct [:action, :params, :collections, :lockTimeout, :waitForSync]

  alias Xarango.Transaction
  alias Xarango.Client

  def execute(transaction) do
    url("")
    |> Client.post(transaction)
    |> to_result
  end

  defp to_result(data) do
    Map.get(data, :result)
  end

  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/transaction/#{path}", options)
  end

end