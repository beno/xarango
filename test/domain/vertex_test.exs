defmodule DomainVertexTest do
  use ExUnit.Case
  doctest Xarango

  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      Xarango.Graph.__destroy_all(_database)
      Xarango.Collection.__destroy_all()
      Xarango.Collection.__destroy_all(_database)
    end
  end

  test "create vertex" do
    vertex = TestVertex.create(%{jabba: "dabba"})
    assert vertex.vertex._data == %{jabba: "dabba"}
  end
  
  test "create vertex in db" do
    vertex = TestDbVertex.create(%{jabba: "dabba"})
    assert vertex.vertex._data == %{jabba: "dabba"} 
  end
  
  test "get one vertex" do
    source = TestVertex.create(%{jabba: "dabba"})
    model = TestVertex.one(%{_id: source.vertex._id})
    assert model.vertex._data == %{jabba: "dabba"}
  end
  
  test "get one model in db" do
    source = TestDbVertex.create(%{jabba: "dabba"})
    model = TestDbVertex.one(%{_id: source.vertex._id})
    assert model.vertex._data == %{jabba: "dabba"}
  end
  
  test "get model list" do
    source = TestVertex.create(%{jabba: "dabba"})
    TestVertex.create(%{dabba: "doo"})
    models = TestVertex.list(%{jabba: "dabba"})
    assert is_list(models)
    assert length(models) == 1
    assert Enum.at(models, 0).vertex._data == source.vertex._data
  end
  
  test "list models in db" do
    source = TestDbVertex.create(%{jabba: "dabba"})
    TestDbVertex.create(%{dabba: "doo"})
    models = TestDbVertex.list(%{jabba: "dabba"})
    assert is_list(models)
    assert length(models) == 1
    assert Enum.at(models, 0).vertex._data == source.vertex._data
  end
  
  
  test "replace model" do
    source = TestVertex.create(%{jabba: "dabba"})
    model = TestVertex.replace(%{_id: source.vertex._id},  %{foo: "bar"})
    assert model.vertex._data == %{foo: "bar"}
  end
  
  test "replace in db" do
    source = TestDbVertex.create(%{jabba: "dabba"})
    model = TestDbVertex.replace(%{_id: source.vertex._id},  %{foo: "bar"})
    assert model.vertex._data == %{foo: "bar"}
  end
  
  test "update model" do
    source = TestVertex.create(%{jabba: "dabba"})
    model = TestVertex.update(%{_id: source.vertex._id},  %{foo: "bar"})
    assert model.vertex._data == %{jabba: "dabba", foo: "bar"}
  end
  
  test "update in db" do
    source = TestDbVertex.create(%{jabba: "dabba"})
    model = TestDbVertex.update(%{_id: source.vertex._id},  %{foo: "bar"})
    assert model.vertex._data == %{jabba: "dabba", foo: "bar"}
  end
  
  test "destroy model" do
    source = TestVertex.create(%{jabba: "dabba"})
    result = TestVertex.destroy(%{_id: source.vertex._id})
    assert result[:removed] == true
  end
  
  test "destroy in db" do
    source = TestDbVertex.create(%{jabba: "dabba"})
    result = TestDbVertex.destroy(%{_id: source.vertex._id})
    assert result[:removed] == true
  end
  
  test "access" do
    model = TestDbVertex.create(%{jabba: "dabba"})
    assert model[:jabba] == "dabba"
  end

  defp _database, do: %Xarango.Database{name: "test_database"}
  
end


defmodule TestVertex do
  use Xarango.Domain.Vertex, graph: :test_graph
end

defmodule TestDbVertex do
  use Xarango.Domain.Vertex, graph: :test_graph, db: :test_database
end


