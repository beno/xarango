defmodule Xarango.AQL do

  defstruct [:collection, :filters, :sort, :limit]

  def from(collection) do
    %Xarango.AQL{collection: collection, filters: []}
  end

  def filter(aql, filters) do
    %Xarango.AQL{aql | filters: add_filters(aql, filters) }
  end
  defdelegate where(aql, filters), to: __MODULE__, as: :filter

  def sort(aql, sort, dir\\:desc) do
    %Xarango.AQL{aql | sort: add_sort(aql, sort, dir) }
  end

  def limit(aql, limit) do
    %Xarango.AQL{aql | limit: add_limit(aql, limit) }
  end

  def to_aql(aql) do
    ["FOR r IN #{aql.collection.name}"]
    |> add_to_query(aql.filters)
    |> add_to_query(aql.sort)
    |> add_to_query(aql.limit)
    |> Kernel.++(["RETURN r"])
    |> Enum.join(" ")
  end
  
  defp add_to_query(query, nil), do: query
  defp add_to_query(query, items) do
    query ++ items
  end
  
  defp add_filters(aql, filters) do
    filters
    |> Enum.reduce(aql.filters, fn {key, value}, f -> f ++ [to_filter(key, value)] end)
  end
  defp to_filter(key, value) when is_binary(value) do
    "FILTER r.#{key} == \"#{value}\""
  end
  defp to_filter(key, value) do
    "FILTER r.#{key} == #{value}"
  end

  defp add_sort(_aql, sort, dir) when is_list(sort) do
    dir = Atom.to_string(dir) |> String.upcase
    sort = Enum.map(sort, fn s -> "r.#{s}" end) |> Enum.join(", ")
    ["SORT #{sort} #{dir}"]
  end
  defp add_sort(_aql, sort, dir) do
    dir = Atom.to_string(dir) |> String.upcase
    ["SORT r.#{sort} #{dir}"]
  end

  defp add_limit(_aql, limit) do
    ["LIMIT #{limit}"]
  end
  
  



end