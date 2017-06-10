defmodule AQLTest do
  use ExUnit.Case
#  import Xarango.TestHelper

  alias Xarango.AQL
  
  test "aql filter" do
    coll = %{name: "products"}
    q = AQL.from(coll)
    |> AQL.filter([foo: "bar", size: 4])
    |> AQL.to_aql
    assert q == "FOR r IN products FILTER r.foo == \"bar\" FILTER r.size == 4 RETURN r"
  end
  
  test "aql limit" do
    coll = %{name: "products"}
    q = AQL.from(coll)
    |> AQL.limit(100)
    |> AQL.to_aql
    assert q == "FOR r IN products LIMIT 100 RETURN r"
  end
  
  test "aql sort" do
    coll = %{name: "products"}
    q = AQL.from(coll)
    |> AQL.sort(:name)
    |> AQL.to_aql
    assert q == "FOR r IN products SORT r.name DESC RETURN r"
  end
  
  test "aql sort multiple ascending" do
    coll = %{name: "products"}
    q = AQL.from(coll)
    |> AQL.sort([:name, :age], :asc)
    |> AQL.to_aql
    assert q == "FOR r IN products SORT r.name, r.age ASC RETURN r"
  end
  
  test "aql all" do
    coll = %{name: "products"}
    q = AQL.from(coll)
    |> AQL.limit(9)
    |> AQL.sort([:name, :age])
    |> AQL.filter([foo: "bar", size: 4])
    |> AQL.where([age: 21])
    |> AQL.to_aql
    assert q == "FOR r IN products FILTER r.foo == \"bar\" FILTER r.size == 4 FILTER r.age == 21 SORT r.name, r.age DESC LIMIT 9 RETURN r"
  end




  

end
