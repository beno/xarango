defmodule Xarango.Transaction do

  defstruct [:action, :params, :collections, :lockTimeout, :waitForSync]

  import Xarango.Client
  use Xarango.URI, prefix: "transaction"

  def execute(transaction) do
    url("")
    |> post(transaction)
    |> to_result
  end

  defp to_result(data) do
    Map.get(data, :result)
  end

end