defmodule Xarango.Index do

  defstruct [:id, :type, :unique, :fields, :selectivityEstimate, :sparse, :isNewlyCreated,
    :geoJson, :constraint, :ignoreNull, :minLength, :error, :code]

  alias Xarango.Index
  import Xarango.Client
  use Xarango.URI, prefix: "index"
  
  defmacro index(type, field) do
    quote do
      @indexes %Index{type: Atom.to_string(unquote(type)), fields: [Atom.to_string(unquote(field))]}
      defp indexes, do: @indexes
      defoverridable [indexes: 0]
    end
  end

  defmacro __using__(_options\\[]) do
    quote do
      Module.register_attribute __MODULE__, :indexes, accumulate: true
      defp indexes, do: @indexes
      defoverridable [indexes: 0]
      import Index, only: [index: 2]
    end
  end
  
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
