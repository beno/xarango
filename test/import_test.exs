defmodule ImportTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Import
  alias Xarango.Collection

  setup do
    on_exit fn ->
      Collection.__destroy_all
    end
  end

  test "import document" do
    collection = Collection.create(collection_())
    documents = Enum.map(1..10, fn _ -> document_() end)
    result = Import.documents(documents, collection)
    assert result.created == 10
  end
end
