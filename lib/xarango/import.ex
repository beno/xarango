defmodule Xarango.Import do

  import Xarango.Client

  def documents(documents, collection, database\\nil) do
    Xarango.URI.path("import", database)
    |> Xarango.Client._url(collection: collection.name, type: "list")
    |> post(documents)
  end
end
