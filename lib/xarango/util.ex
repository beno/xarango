defmodule Xarango.Util do

  def name_from(module) do
    module
    |> Module.split
    |> Enum.join("")
    |> Macro.underscore
  end

  def short_name_from(module) do
    module
    |> Module.split
    |> List.last
    |> Macro.underscore
  end

  def do_decode(response) do
    case response do
      %HTTPoison.Response{status_code: status_code, body: body} when status_code >= 200 and status_code < 300 ->
        {:ok, Poison.decode!(body, keys: :atoms)}
      %HTTPoison.Response{body: body} ->
        {:error, Poison.decode!(body, keys: :atoms)}
      %HTTPoison.Error{reason: reason} -> do_error reason
    end
  end

  def do_encode(body) when is_map(body) do
    encode_map(body)
  end

  def do_encode(body) do
    body
  end

  defp encode_map(body) do
    body
    |> compact
    |> encode_data
    |> Enum.into(%{})
  end

  defp compact(body) when is_list(body) do
    Enum.map(body, &compact(&1))
  end

  defp compact(body) when is_map(body) do
    case body do
      %{:__struct__ => _} = body -> Map.from_struct(body)
      body -> body
    end
    |> Enum.reject(&match?({_,nil}, &1))
    |> Enum.map(fn {key, value} -> {key, compact(value)} end)
    |> Enum.into(%{})
  end

  defp compact(body), do: body

  defp encode_data(body) do
    case body[:_data] do
      nil -> body
      data -> Map.delete(body, :_data) |> Map.merge(data)
    end
  end

  def decode_data(doc, struct) do
    case pluck_data(doc, struct) do
      data when data == %{} ->  doc
      data -> Map.put(doc, :_data, data)
    end
  end

  defp pluck_data(doc, struct) do
    keys = Map.keys(struct.__struct__)
    Enum.reduce(doc, %{}, fn {k,v}, acc ->
      if v == nil || Enum.member?(keys, k), do: acc, else: Map.put(acc, k, v)
    end)
  end

  def do_error(msg) do
    raise Xarango.Error, message: msg
  end

  def to_json(items) when is_list(items) do
    items
    |> Enum.map(&to_resource(&1))
    |> Poison.encode!
  end

  def to_json(item) do
    to_resource(item)
    |> Poison.encode!
  end

  def to_resource(resource, options\\[])
  def to_resource(resources, options) when is_list(resources), do: resources |> Enum.map(&to_resource(&1, options))
  def to_resource(%{vertex: vertex} = node, options), do: vertex |> to_resource(options) |> add_resource_relationships(node, options)
  def to_resource(%{doc: document}, options), do: document |> to_resource(options)
  def to_resource(%{result: result}, options), do: result |> to_resource(options)
  def to_resource(%{_data: data, _id: id}, options) do
    id = options[:encode_id] == true && form_encode(id) || id
    %{id: id}
    |> Map.merge(data || %{})
  end
  defp add_resource_relationships(resource, node, options) do
    case node[:id] do
      nil -> resource
      node_id ->
        relationships = get_edges(node)
        |> Enum.reduce(%{}, fn edge, edges ->
          relationship = Xarango.Edge.collection(edge).collection |> String.to_atom
          case edge do
            %{_from: ^node_id, _to: to} -> add_resource_relationship(edges, relationship, to, options)
            %{_from: from, _to: ^node_id} -> add_resource_relationship(edges, relationship, from, options)
            _ -> edges
          end
        end)
        Map.merge(resource, relationships)
    end
  end
  defp get_edges(node) do
    %Xarango.Traversal{startVertex: node[:id],
                       graphName: node.__struct__._graph([]).name,
                       uniqueness: %{edges: "path", vertices: "path"},
                       direction: "any"}
    |> Xarango.Traversal.traverse
    |> Xarango.TraversalResult.edges
  end
  defp add_resource_relationship(edges, relationship, target_id, options) do
    target_id = case options[:encode_id] do
      true -> form_encode(target_id)
      _ -> target_id
    end
    case edges[relationship] do
      nil -> Map.put(edges, relationship, target_id)
      id when is_binary(id) -> Map.put(edges, relationship, [id, target_id] )
      ids when is_list(ids) -> Map.put(edges, relationship, ids ++ [target_id])
    end
  end

  defp form_encode(id) do
    case id do
      nil -> nil
      id -> URI.encode_www_form(id)
    end
  end

  def to_javascript(value) do
    jsify(value)
  end

  defp jsify(map) when is_map(map) do
    Xarango.Util.do_encode(map)
    |> Enum.reduce([], fn {key, value}, js ->
      js ++ ["#{key}: #{jsify(value)}"]
    end)
    |> Enum.intersperse(", ")
    |> List.to_string
    |> wrap("{", "}")
  end
  defp jsify(list) when is_list(list) do
    list
    |> Enum.reduce([], fn value, js ->
      js ++ [jsify(value)]
    end)
    |> Enum.intersperse(", ")
    |> List.to_string
    |> wrap("[", "]")
  end
  defp jsify(value) when is_binary(value), do: wrap(value, "\"", "\"")
  defp jsify(nil), do: "null"
  defp jsify(value) when is_atom(value) do
    cond do
      is_module(value) -> Xarango.Util.name_from(value)
      true -> Atom.to_string(value)
    end
  end
  defp jsify(value), do: value


  def wrap(nil, _, _), do: ""
  def wrap("", _, _), do: ""
  def wrap(js, left, right), do: left <> js <> right

  def is_module(val) do
    Atom.to_string(val) =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def stringify_keys(nil), do: nil
  def stringify_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {stringify(k), v} end)
    |> Enum.into(%{})
  end
  def stringify_keys([head | rest]) do
    [stringify_keys(head) | stringify_keys(rest)]
  end
  def stringify_keys(not_a_map) do
    not_a_map
  end
  defp stringify(value) when is_atom(value) do
    Atom.to_string(value)
  end
  defp stringify(value) do
    value
  end



end
