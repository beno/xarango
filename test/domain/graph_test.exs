defmodule DomainGraphTest do
  use ExUnit.Case
  doctest Xarango

  # alias Xarango.Domain.Graph
  
  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      try do Xarango.Graph.__destroy_all(_database) rescue _ -> nil end
      Xarango.Collection.__destroy_all()
      try do Xarango.Collection.__destroy_all(_database) rescue _ -> nil end
    end
  end

  test "create graph" do
    graph = TestGraph.create
    assert length(graph.graph.edgeDefinitions) == 2
    assert length(graph.graph.orphanCollections) == 3
  end
  
  test "add relationships" do
    TestGraph.create
    p1 = Person.create(%{name: "Alice"})
    p2 = Person.create(%{name: "Bob"})
    outback = Car.create(%{type: "Outback"})
    impreza = Car.create(%{type: "Impreza"})
    subaru = Brand.create(%{name: "Subaru"})
    likes = TestGraph.add_likes(p1, p2)
    has_brand = TestGraph.add_has_brand(outback, subaru)
    TestGraph.add_has_brand(impreza, subaru)
    assert String.starts_with?(likes._id, "likes/")
    assert String.starts_with?(has_brand._id, "has_brand/")
  end
  
  test "list relationships" do
    TestGraph.create
    alice = Person.create(%{name: "Alice"})
    bob = Person.create(%{name: "Bob"})
    jim = Person.create(%{name: "Jim"})
    TestGraph.add_likes(alice, bob)
    TestGraph.add_likes(alice, jim)
    TestGraph.add_likes(bob, alice)
    alice_likes = TestGraph.likes_person(alice)
    alice_liked_by = TestGraph.person_likes(alice)
    assert length(alice_likes) == 2
    assert length(alice_liked_by) == 1
  end
  
  test "list db relationships" do
    TestDbGraph.create
    alice = DbPerson.create(%{name: "Alice"})
    bob = DbPerson.create(%{name: "Bob"})
    jim = DbPerson.create(%{name: "Jim"})
    TestDbGraph.add_likes(alice, bob)
    TestDbGraph.add_likes(alice, jim)
    TestDbGraph.add_likes(bob, alice)
    alice_likes = TestDbGraph.likes_db_person(alice)
    alice_liked_by = TestDbGraph.db_person_likes(alice)
    assert length(alice_likes) == 2
    assert length(alice_liked_by) == 1
  end
  
  test "remove relationships" do
    TestGraph.create
    alice = Person.create(%{name: "Alice"})
    bob = Person.create(%{name: "Bob"})
    TestGraph.add_likes(alice, bob)
    result = TestGraph.remove_likes(alice, bob)
    alice_likes = TestGraph.likes_person(alice)
    assert length(result) == 1
    assert Enum.at(result, 0)[:removed] == true
    assert length(alice_likes) == 0
  end

  test "remove db relationships" do
    TestDbGraph.create
    alice = DbPerson.create(%{name: "Alice"})
    bob = DbPerson.create(%{name: "Bob"})
    TestDbGraph.add_likes(alice, bob)
    result = TestDbGraph.remove_likes(alice, bob)
    alice_likes = TestDbGraph.likes_db_person(alice)
    assert length(result) == 1
    assert Enum.at(result, 0)[:removed] == true
    assert length(alice_likes) == 0
  end

  test "create db graph" do
    graph = TestDbGraph.create
    assert length(graph.graph.edgeDefinitions) == 2
    assert length(graph.graph.orphanCollections) == 3
  end
  
  test "add db relationships" do
    TestDbGraph.create
    outback = DbCar.create(%{type: "Outback"})
    impreza = DbCar.create(%{type: "Impreza"})
    subaru = DbBrand.create(%{name: "Subaru"})
    TestDbGraph.add_has_brand(outback, subaru)
    TestDbGraph.add_has_brand(impreza, subaru)
    subaru_cars = TestDbGraph.db_car_has_brand(subaru)
    outback_brands = TestDbGraph.has_brand_db_brand(outback)
    assert length(outback_brands) == 1
    assert length(subaru_cars) == 2
  end

  
  defp _database do
    %Xarango.Database{name: "test_db"}
  end
end

defmodule Person, do: use Xarango.Domain.Vertex, graph: :test_graph
defmodule Car, do: use Xarango.Domain.Vertex, graph: :test_graph
defmodule Brand, do: use Xarango.Domain.Vertex, graph: :test_graph

defmodule TestGraph do
  use Xarango.Domain.Graph
  
  relationship :person, :likes, :person
  relationship :car, :has_brand, :brand

end

defmodule DbPerson, do: use Xarango.Domain.Vertex, graph: :test_graph, db: :test_db
defmodule DbCar, do: use Xarango.Domain.Vertex, graph: :test_graph, db: :test_db
defmodule DbBrand, do: use Xarango.Domain.Vertex, graph: :test_graph, db: :test_db


defmodule TestDbGraph do
  use Xarango.Domain.Graph, db: :test_db

  relationship :db_person, :likes, :db_person
  relationship :db_car, :has_brand, :db_brand

end

