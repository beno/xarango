defmodule Xarango.Index do
  
  defstruct [:id, :type, :unique, :fields, :selectivityEstimate, :sparse, :isNewlyCreated, 
    :geoJson, :constraint, :ignoreNull, :minLength, :error, :code]
  
  alias Xarango.Index
  alias Xarango.Client
  
  def create(%Index{type: type} = index, collection) when not is_nil(type) do
    url("", collection: collection.name)
    |> Client.post(index)
    |> to_index
  end
  
  def destroy(index) do
    url(index.id)
    |> Client.delete
  end
  
  defp to_index(data) do
    struct(Index, data)
  end
  
  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/index/#{path}", options)
  end
  
end