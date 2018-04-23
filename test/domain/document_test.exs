defmodule DomainDocumentTest do
  use ExUnit.Case
  doctest Xarango

  setup do
    on_exit fn ->
      try do Xarango.Collection.__destroy_all() rescue _ -> nil end
      try do Xarango.Collection.__destroy_all(_database()) rescue _ -> nil end
      try do Xarango.Database.destroy(_database()) rescue _ -> nil end
    end
  end

  test "create model" do
    model = TestModel.create(%{jabba: "dabba"})
    assert model.doc._data == %{jabba: "dabba"}
  end

  test "create model in graph" do
    model = TestModel.create(%{jabba: "dabba"})
    assert model.doc._data == %{jabba: "dabba"}
  end


  test "create model in db" do
    model = TestDbModel.create(%{jabba: "dabba"})
    assert model.doc._data == %{jabba: "dabba"}
  end

  test "get one model" do
    source = TestModel.create(%{jabba: "dabba"})
    model = TestModel.one(%{_id: source.doc._id})
    assert model.doc._data == %{jabba: "dabba"}
  end

  test "return nil" do
    model = TestModel.one?(%{_id: "DOESNTEXIST"})
    assert model == nil
  end

  test "get one model in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    model = TestDbModel.one(%{_id: source.doc._id})
    assert model.doc._data == %{jabba: "dabba"}
  end

  test "get model list" do
    source = TestModel.create(%{jabba: "dabba"})
    TestModel.create(%{dabba: "doo"})
    result = TestModel.list(%{jabba: "dabba"})
    assert is_list(result.result)
    assert length(result.result) == 1
    assert Enum.at(result.result, 0).doc._data == source.doc._data
  end

  test "get model list with pagination" do
    1..10 |> Enum.each(fn idx -> TestModel.create(%{name: "#{idx}"}) end)
    result = TestModel.list(%{}, [sort: :name, per_page: 2])
    refute is_nil(result.id)
    assert is_list(result.result)
    assert length(result.result) == 2
  end

  test "get model next list with cursor" do
    1..10 |> Enum.each(fn idx -> TestModel.create(%{name: "#{idx}"}) end)
    result = TestModel.list(%{}, [sort: :name, per_page: 4])
    refute is_nil(result.id)
    assert is_list(result.result)
    assert length(result.result) == 4
    result2 = TestModel.list(%{}, [cursor: result.id])
    assert result.id == result2.id
    assert length(result2.result) == 4
    result3 = TestModel.list(%{}, [cursor: result.id])
    assert result3.id == nil
    assert length(result3.result) == 2
  end

  test "get model next list with pages" do
    1..10 |> Enum.each(fn idx -> TestModel.create(%{name: "#{idx}"}) end)
    result = TestModel.list(%{}, [sort: :name, per_page: 4, page: 1])
#    refute is_nil(result.id)
    assert is_list(result.result)
    assert length(result.result) == 4
    result2 = TestModel.list(%{}, [sort: :name, per_page: 4, page: 2])
    assert result.id == result2.id
    assert length(result2.result) == 4
    result3 = TestModel.list(%{}, [sort: :name, per_page: 4, page: 3])
    assert result3.id == nil
    assert length(result3.result) == 2
  end



  test "list models in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    TestDbModel.create(%{dabba: "doo"})
    result = TestDbModel.list(%{jabba: "dabba"})
    assert is_list(result.result)
    assert length(result.result) == 1
    assert Enum.at(result.result, 0).doc._data == source.doc._data
  end


  test "replace model" do
    source = TestModel.create(%{jabba: "dabba"})
    model = TestModel.replace(source,  %{foo: "bar"})
    assert model.doc._data == %{foo: "bar"}
  end

  test "replace in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    model = TestDbModel.replace(source,  %{foo: "bar"})
    assert model.doc._data == %{foo: "bar"}
  end

  test "update model" do
    source = TestModel.create(%{jabba: "dabba"})
    model = TestModel.update(source,  %{foo: "bar"})
    assert model.doc._data == %{jabba: "dabba", foo: "bar"}
  end

  test "update in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    model = TestDbModel.update(source,  %{foo: "bar"})
    assert model.doc._data == %{jabba: "dabba", foo: "bar"}
  end

  test "destroy model" do
    source = TestModel.create(%{jabba: "dabba"})
    result = TestModel.destroy(source)
    assert result[:_id] == source.doc._id
  end

  test "destroy in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    result = TestDbModel.destroy(source)
    assert result[:_id] == source.doc._id
  end

  test "access" do
    model = TestDbModel.create(%{jabba: "dabba"})
    assert model[:jabba] == "dabba"
  end

  test "creates index for model and searches it" do
    model = TestDbIndexModel.create(%{jabba: "dabba"})
    result = TestDbIndexModel.search(:jabba, "dab")
    assert model[:id] == Enum.at(result, 0)[:id]
  end

  test "create geo index and run within query" do
    model = TestDbIndexModel.create(%{jabba: "test", location: [47.618336,-122.201141]})
    result = TestDbIndexModel.within([47.619240, -122.203019], 200, :distance)
    assert model[:id] == Enum.at(result, 0)[:id]
  end

  test "create geo index and run near query" do
    model = TestDbIndexModel.create(%{jabba: "test", location: [47.618336,-122.201141]})
    result = TestDbIndexModel.near([47.619240, -122.203019], 10, :distance)
    assert model[:id] == Enum.at(result, 0)[:id]
  end

  defp _database do
    %Xarango.Database{name: "test_db"}
  end
end

defmodule TestModel do
  use Xarango.Domain.Document
end

defmodule TestDbModel do
  use Xarango.Domain.Document, db: :test_db
end

defmodule TestDbIndexModel do
  use Xarango.Domain.Document, db: :test_db

  index :fulltext, :jabba
  index :geo, :location
end
