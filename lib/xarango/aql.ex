defmodule Xarango.AQL do

  defstruct [:graph, :collection, :filters, :sort, :limit, :skip, :for, :options, :return]

  def from(collection) do
    collection = collection_name(collection)
    %Xarango.AQL{filters: [], collection: collection, for: "FOR x IN #{collection}", return: "RETURN x"}
  end

  def any(%{vertex: %{_id: node_id}}, relation) do
    %Xarango.AQL{filters: [], for: "FOR x IN ANY '#{node_id}' #{relation}", return: "RETURN x"}
  end
  def any(%{vertex: %{_id: from_id}}, relation, %{vertex: %{_id: to_id}}) do
    %Xarango.AQL{filters: [], for: "FOR x, y IN ANY SHORTEST_PATH '#{from_id}' TO '#{to_id}' #{relation}", return: "RETURN [x, y]"}
  end
  def outbound(%{vertex: %{_id: node_id}}, relation) do
    outbound(%{id: node_id}, relation)
  end
  def outbound(%{id: node_id}, relation) do
    %Xarango.AQL{filters: [], for: "FOR x IN OUTBOUND '#{node_id}' #{relation}", return: "RETURN x"}
  end
  def outbound(%{vertex: %{_id: from_id}}, relation, %{vertex: %{_id: to_id}}) do
    %Xarango.AQL{filters: [], for: "FOR x, y IN OUTBOUND SHORTEST_PATH '#{from_id}' TO '#{to_id}' #{relation}", return: "RETURN [x, y]"}
  end
  def inbound(%{vertex: %{_id: node_id}}, relation) do
    inbound(%{id: node_id}, relation)
  end
  def inbound(%{id: node_id}, relation) do
    %Xarango.AQL{filters: [], for: "FOR x IN INBOUND '#{node_id}' #{relation}", return: "RETURN x"}
  end
  def inbound(%{vertex: %{_id: from_id}}, relation, %{vertex: %{_id: to_id}}) do
    %Xarango.AQL{filters: [], for: "FOR x, y IN INBOUND SHORTEST_PATH '#{from_id}' TO '#{to_id}' #{relation}", return: "RETURN [x, y]"}
  end



  def filter(aql, filters) do
    %Xarango.AQL{aql | filters: parse_filters(aql, filters) }
  end
  defdelegate where(aql, filters), to: __MODULE__, as: :filter

  def sort(aql, sort, dir\\:asc) do
    %Xarango.AQL{aql | sort: parse_sort(aql, sort, dir) }
  end

  def limit(aql, limit, skip\\nil) do
    %Xarango.AQL{aql | limit: parse_limit(aql, limit, skip) }
  end

  def options(aql, options) do
    %Xarango.AQL{aql | options: parse_options(aql, options) }
  end

  def graph(aql, graph) do
    %Xarango.AQL{aql | graph: parse_graph(aql, graph) }
  end

  def fulltext(aql, field, value) do
    %Xarango.AQL{aql | for: parse_fulltext(aql, field, value)}
  end

  def to_aql(aql) do
    [aql.for]
    |> add_to_query(aql.graph)
    |> add_to_query(aql.filters)
    |> add_to_query(aql.sort)
    |> add_to_query(aql.options)
    |> add_to_query(aql.limit)
    |> Kernel.++([aql.return])
    |> Enum.join(" ")
    |> String.replace("\"", "'")
  end

  defp add_to_query(query, nil), do: query
  defp add_to_query(query, items) do
    query ++ items
  end

  defp parse_filters(aql, filters) do
    filters
    |> Enum.reduce(aql.filters, fn {key, value}, f -> f ++ [to_filter(key, value)] end)
  end
  defp to_filter(key, value) when is_binary(value) do
    "FILTER x.#{key} == '#{value}'"
  end
  defp to_filter(key, value) do
    "FILTER x.#{key} == #{value}"
  end

  defp parse_sort(_aql, sort, dir) when is_list(sort) do
    dir = Atom.to_string(dir) |> String.upcase
    sort = Enum.map(sort, fn s -> "x.#{s}" end) |> Enum.join(", ")
    ["SORT #{sort} #{dir}"]
  end
  defp parse_sort(_aql, sort, dir) do
    dir = Atom.to_string(dir) |> String.upcase
    ["SORT x.#{sort} #{dir}"]
  end

  def parse_options(_aql, options) do
    options = options |> Enum.into(%{}) |> Xarango.Util.to_javascript
    ["OPTIONS #{options}"]
  end

  defp parse_limit(_aql, limit, nil) do
    ["LIMIT #{limit}"]
  end
  defp parse_limit(_aql, limit, skip) do
    ["LIMIT #{skip}, #{limit}"]
  end

  defp parse_graph(_aql, graph) do
    graph_name = case graph do
      %{name: name} -> name
      name -> name
    end
    ["GRAPH '#{graph_name}'"]
  end

  defp parse_fulltext(aql, field, value, type\\"prefix:") do
    "FOR x IN FULLTEXT(#{aql.collection}, '#{field}', '#{type}#{value}')"
  end

  defp collection_name(collection) do
    case collection do
      %{name: name} -> name
      %{collection: name} -> name
      name when is_binary(name) -> name
    end
  end

end