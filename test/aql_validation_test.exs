defmodule AqlCar do
  use Xarango.Domain.Node, graph: AqlVehicles
  schema [name: :string]
end
defmodule AqlDriver do
  use Xarango.Domain.Node, graph: AqlVehicles
  schema [name: :string]
end
defmodule AqlBrand do
  use Xarango.Domain.Node, graph: AqlVehicles
  schema [name: :string]
end

defmodule AqlVehicles do
  use Xarango.Domain.Graph, db: :aql_db

  relationship AqlCar, :built_by, AqlBrand
  relationship AqlDriver, :drives, AqlCar
  relationship AqlDriver, :likes, AqlBrand
  relationship AqlDriver, :likes, AqlDriver

end


defmodule AQLValdationTest do
  use ExUnit.Case

  alias Xarango.AQL
  alias Xarango.Query

  defp db, do: %Xarango.Database{name: "aql_db"}
  defp assert_names(aql, expectation) do
    result = Query.query(aql, db())
    |> Map.get(:result)
    |> Enum.map(fn %{name: name} -> name end)
    assert result == expectation
  end
  defp assert_edges(aql, expectation) do
    result = Query.query(aql, db())
    |> Xarango.QueryResult.to_edge
    |> Enum.at(0)
    case expectation do
      nil ->
        assert result == nil
      %{_from: from_id, _to: to_id} ->
        assert result._from == from_id
        assert result._to == to_id
    end
  end

  defp car(objects, nr), do: Enum.at(objects[:cars], nr-1)
  defp brand(objects, nr), do: Enum.at(objects[:brands], nr-1)
  defp driver(objects, nr), do: Enum.at(objects[:drivers], nr-1)

  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all
      Xarango.Collection.__destroy_all
    end

    brands = 1..3 |> Enum.map(&AqlBrand.create(%{name: "Brand #{&1}"}))
    cars = 1..6 |> Enum.map(&AqlCar.create(%{name: "Car #{&1}"}))
    drivers = 1..6 |> Enum.map(&AqlDriver.create(%{name: "Driver #{&1}"}))

    cars |> Enum.with_index |> Enum.each(fn {car, idx} -> AqlVehicles.add_built_by(car, Enum.at(brands, Integer.mod(idx, 3))) end)
    drivers |> Enum.with_index |> Enum.each(fn {driver, idx} -> AqlVehicles.add_drives(driver, Enum.at(cars, idx)) end)
    objects = %{cars: cars, drivers: drivers, brands: brands}
    AqlVehicles.add(driver(objects, 2), :likes, driver(objects, 1))
    AqlVehicles.add(driver(objects, 1), :likes, brand(objects, 1))
    AqlVehicles.add(driver(objects, 1), :likes, brand(objects, 2))

    AqlVehicles.add(driver(objects, 2), :likes, driver(objects, 3))
    AqlVehicles.add(driver(objects, 2), :likes, driver(objects, 4))
    AqlVehicles.add(driver(objects, 4), :likes, driver(objects, 2))
    AqlVehicles.add(driver(objects, 3), :likes, driver(objects, 2))
    {:ok, objects}

  end

  test "any vertices", objects do
    AQL.any(car(objects, 3), :built_by)
    |> assert_names(["Brand 3"])
  end

  test "inbound vertices", objects do
    AQL.inbound(brand(objects, 1), :built_by)
    |> assert_names(["Car 1", "Car 4"])
  end

  test "outbound vertices", objects do
    AQL.outbound(driver(objects, 5), :drives)
    |> assert_names(["Car 5"])
  end

  test "any vertices multiple", objects do
    AQL.any(driver(objects, 1), :likes)
    |> assert_names(["Brand 1", "Brand 2", "Driver 2"])
  end

  test "inbound vertices multiple", objects do
    AQL.inbound(driver(objects, 1), :likes)
    |> assert_names(["Driver 2"])
  end

  test "outbound vertices multiple", objects do
    AQL.outbound(driver(objects, 1), :likes)
    |> assert_names(["Brand 1", "Brand 2"])
  end

  describe "edges" do
    test "any edges", objects do
      driver2 = driver(objects, 2)
      driver4 = driver(objects, 4)
      AQL.any(driver2, :likes, driver4)
      |> assert_edges(%{_from: driver4[:id], _to: driver2[:id]})
    end

    test "any edges rev", objects do
      driver2 = driver(objects, 2)
      driver4 = driver(objects, 4)
      AQL.any(driver4, :likes, driver2)
      |> assert_edges(%{_from: driver2[:id], _to: driver4[:id]})
    end

    test "outbound edges", objects do
      driver2 = driver(objects, 2)
      driver4 = driver(objects, 4)
      AQL.outbound(driver2, :likes, driver4)
      |> assert_edges(%{_from: driver2[:id], _to: driver4[:id]})
    end

    test "inbound edges", objects do
      driver2 = driver(objects, 2)
      driver4 = driver(objects, 4)
      AQL.inbound(driver2, :likes, driver4)
      |> assert_edges(%{_from: driver4[:id], _to: driver2[:id]})
    end

    test "non existing egdes", objects do
      driver1 = driver(objects, 1)
      driver5 = driver(objects, 5)
      AQL.inbound(driver1, :likes, driver5)
      |> assert_edges(nil)
    end
  end

end

