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
  
  test "get one model in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    model = TestDbModel.one(%{_id: source.doc._id})
    assert model.doc._data == %{jabba: "dabba"}
  end
  
  test "get model list" do
    source = TestModel.create(%{jabba: "dabba"})
    TestModel.create(%{dabba: "doo"})
    models = TestModel.list(%{jabba: "dabba"})
    assert is_list(models)
    assert length(models) == 1
    assert Enum.at(models, 0).doc._data == source.doc._data
  end
  
  test "list models in db" do
    source = TestDbModel.create(%{jabba: "dabba"})
    TestDbModel.create(%{dabba: "doo"})
    models = TestDbModel.list(%{jabba: "dabba"})
    assert is_list(models)
    assert length(models) == 1
    assert Enum.at(models, 0).doc._data == source.doc._data
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
end