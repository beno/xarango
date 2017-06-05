defmodule DomainNodeTest do
  use ExUnit.Case
  doctest Xarango

  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      Xarango.Graph.__destroy_all(_database())
      Xarango.Collection.__destroy_all()
      Xarango.Collection.__destroy_all(_database())
    end
  end

  test "create node" do
    node = TestNode.create(%{jabba: "dabba"})
    assert node.vertex._data == %{jabba: "dabba"}
  end

  test "create node in graph" do
    node = TestNode.create(%{jabba: "dabba"}, graph: NodeTestGraph2)
    assert node.vertex._data == %{jabba: "dabba"}
  end

  test "create no graph node in graph" do
    node = TestNoGraphNode.create(%{jabba: "dabba"}, graph: NodeTestGraph2)
    assert node.vertex._data == %{jabba: "dabba"}
  end

  test "error when graph not set" do
    assert_raise Xarango.Error, fn ->
      TestNoGraphNode.create(%{jabba: "dabba"})
    end
  end

  test "create node in db" do
    node = TestDbNode.create(%{jabba: "dabba"})
    assert node.vertex._data == %{jabba: "dabba"}
  end

  test "get one node" do
    source = TestNode.create(%{jabba: "dabba"})
    model = TestNode.one(%{_id: source.vertex._id})
    assert model.vertex._data == %{jabba: "dabba"}
  end

  test "get one model in db" do
    source = TestDbNode.create(%{jabba: "dabba"})
    model = TestDbNode.one(%{_id: source.vertex._id})
    assert model.vertex._data == %{jabba: "dabba"}
  end

  test "get model list" do
    source = TestNode.create(%{jabba: "dabba"})
    TestNode.create(%{dabba: "doo"})
    models = TestNode.list(%{jabba: "dabba"})
    assert is_list(models)
    assert length(models) == 1
    assert Enum.at(models, 0).vertex._data == source.vertex._data
  end

  test "list nodes in db" do
    source = TestDbNode.create(%{jabba: "dabba"})
    TestDbNode.create(%{dabba: "doo"})
    models = TestDbNode.list(%{jabba: "dabba"})
    assert is_list(models)
    assert length(models) == 1
    assert Enum.at(models, 0).vertex._data == source.vertex._data
  end

  test "replace node" do
    source = TestNode.create(%{jabba: "dabba"})
    model = TestNode.replace(source,  %{foo: "bar"})
    assert model.vertex._data == %{foo: "bar"}
  end

  test "replace node in db" do
    source = TestDbNode.create(%{jabba: "dabba"})
    model = TestDbNode.replace(source,  %{foo: "bar"})
    assert model.vertex._data == %{foo: "bar"}
  end

  test "update node" do
    source = TestNode.create(%{jabba: "dabba"})
    model = TestNode.update(source,  %{foo: "bar"})
    assert model.vertex._data == %{jabba: "dabba", foo: "bar"}
  end

  test "update node in db" do
    source = TestDbNode.create(%{jabba: "dabba"})
    model = TestDbNode.update(source,  %{foo: "bar"})
    assert model.vertex._data == %{jabba: "dabba", foo: "bar"}
  end

  test "destroy node" do
    source = TestNode.create(%{jabba: "dabba"})
    result = TestNode.destroy(source)
    assert result[:removed] == true
  end

  test "destroy node in db" do
    source = TestDbNode.create(%{jabba: "dabba"})
    result = TestDbNode.destroy(source)
    assert result[:removed] == true
  end

  test "access" do
    model = TestDbNode.create(%{jabba: "dabba"})
    assert model[:jabba] == "dabba"
  end
  
  test "creates index for model and searches it" do
    model = TestIndexNode.create(%{jabba: "dabba"})
    result = TestIndexNode.search(:jabba, "dab")
    assert model[:id] == Enum.at(result, 0)._id
  end

  defp _database, do: %Xarango.Database{name: "test_database"}

end

defmodule NodePerson do
  use Xarango.Domain.Node, graph: NodeTestGraph
end

defmodule NodeTestGraph do
  use Xarango.Domain.Graph

  relationship NodePerson, :likes, NodePerson
end

defmodule NodeTestGraph2 do
  use Xarango.Domain.Graph
end

defmodule TestNoGraphNode do
  use Xarango.Domain.Node
end

defmodule TestNodeDbGraph do
  use Xarango.Domain.Graph, db: :test_database
end

defmodule TestNode do
  use Xarango.Domain.Node, graph: NodeTestGraph
end

defmodule TestDbNode do
  use Xarango.Domain.Node, graph: TestNodeDbGraph
end
<<<<<<< HEAD

defmodule TestIndexNode do
  use Xarango.Domain.Node, graph: NodeTestGraph
  
  index :fulltext, :jabba
end



=======
>>>>>>> origin/master
