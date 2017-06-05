defmodule Xarango.Index do
  
  defstruct [:id, :type, :unique, :fields, :selectivityEstimate, :sparse, :isNewlyCreated, 
    :geoJson, :constraint, :ignoreNull, :minLength, :error, :code]
  
  alias Xarango.Index
  import Xarango.Client
  use Xarango.URI, prefix: "index"
  
  def create(%Index{type: type} = index, collection_name, database\\nil) when not is_nil(type) do
    url("", database, collection: collection_name)
    |> post(index)
    |> to_index
  end
  
  def destroy(index, database\\nil) do
    url(index.id, database)
    |> delete
  end
  
  defp to_index(data) do
    struct(Index, data)
  end
    
end