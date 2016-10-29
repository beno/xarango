defmodule DomainVertexTest do
  use ExUnit.Case
  doctest Xarango

  # setup do
  #   on_exit fn ->
  #     # try do Xarango.Collection.destroy(%Xarango.Collection{name: "test_collection"}) rescue _ -> nil end
  #     # try do Xarango.Collection.destroy(%Xarango.Collection{name: "test_collection"}, _database) rescue _ -> nil end
  #     # try do Xarango.Database.destroy(_database) rescue _ -> nil end
  #   end
  # end

  test "create graph" do
    model = TestVertex.create(%{jabba: "dabba"})
    assert model.vertex._data == %{jabba: "dabba"} 
  end
  
  test "create graph in db" do
    model = TestDbVertex.create(%{jabba: "dabba"})
    assert model.vertex._data == %{jabba: "dabba"} 
  end
  

  
end

defmodule TestVertex do
  use Xarango.Domain.Vertex
  
  collection :test_collection, :test_graph
  
end

defmodule TestDbVertex do
  use Xarango.Domain.Vertex

  collection :test_collection, :test_graph, :test_database

end


