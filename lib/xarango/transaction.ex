defmodule Xarango.Transaction do

  defstruct action: [], params: %{}, collections: %{read: [], write: []}, lockTimeout: 0, waitForSync: false, return: nil

  import Xarango.Client
  alias Xarango.Transaction
  alias Xarango.Edge
  alias Xarango.Vertex
  use Xarango.URI, prefix: "transaction"
  
  def begin(), do: %Transaction{}
  def begin(graph) do
    apply(graph, :ensure, [])
    %Transaction{}
  end

  def execute(transaction, database\\nil) do
    return_type = transaction.return
    transaction = finalize(transaction)
    url("", database)
    |> post(transaction)
    |> Map.get(:result)
    |> to_result(return_type, database)
  end
  
  defp finalize(%{action: action} = transaction) when is_binary(action) do
    %Transaction{transaction | return: nil}
  end
  defp finalize(%{action: action} = transaction) when is_list(action) do
    [return_action | rest] = Enum.reverse(action)
    action = (["return " <> return_action] ++ rest)
      |> Enum.reverse
      |> Enum.join("; ")
    action = fnwrap("var db = require('@arangodb').db;" <> action)
    %Transaction{transaction | action: action, return: nil}
  end
  
  def create(transaction, node_module, data, options\\[]) do
    collection = Xarango.Util.name_from(node_module)
    action = "db.#{collection}.save(#{jsify(data)})"
    action = parameterize(options[:var], action, node_module)
    merge(transaction, %Transaction{action: action, collections: %{write: [collection]}, return: node_module})
  end
  
  def ensure(transaction, node_module, data, options\\[]) do
    collection = Xarango.Util.name_from(node_module)
    action = "(db.#{collection}.firstExample(#{jsify(data)}) || db.#{collection}.save(#{jsify(data)}))"
    action = parameterize(options[:var], action, node_module)
    merge(transaction, %Transaction{action: action, collections: %{write: [collection]}, return: node_module})
  end
  
  def destroy(transaction, node_module, node) do
    collection = Xarango.Util.name_from(node_module)
    action = "(db.#{collection}.delete(#{jsify(node.vertex)}))"
    merge(transaction, %Transaction{action: action, collections: %{write: [collection]}})
  end
  
  def add(transaction, from, relationship, to, data\\nil) do
    edge = %Edge{_from: vertex_id(from),  _to: vertex_id(to), _data: data} |> jsify
    action = "db.#{relationship}.save(#{edge})"
    merge(transaction, %Transaction{action: action, collections: %{write: [relationship]}, return: Edge})
  end

  def add?(transaction, from, relationship, to, data\\nil) do
    edge = %Edge{_from: vertex_id(from),  _to: vertex_id(to), _data: data} |> jsify
    action = "(db.#{relationship}.firstExample(#{edge}) || db.#{relationship}.save(#{edge}))"
    merge(transaction, %Transaction{action: action, collections: %{write: [relationship], read: [relationship]}, return: Edge})
  end
  
  def remove(transaction, from, relationship, to) do
    edge = %Edge{_from: vertex_id(from),  _to: vertex_id(to)} |> jsify
    action = "db.#{relationship}.removeByExample(#{edge})"
    merge(transaction, %Transaction{action: action, collections: %{write: [relationship]}})
  end

  def get(transaction, var, type) do
    action = "{_id: #{var}}"
    merge(transaction, %Transaction{action: action, return: {type, :_id}})
  end
  def get(transaction, from, relationship, to) do
    {edge, return_type} = cond do
      is_module(to) -> {%Edge{_from: vertex_id(from)}, {to, :_to}}
      is_module(from) -> {%Edge{_to: vertex_id(to)}, {from, :_from}}
    end
    action = "db.#{relationship}.byExample(#{jsify(edge)}).toArray()" 
    merge(transaction, %Transaction{action: action, collections: %{read: [relationship]}, return: return_type})
  end
  
  defp is_module(val) do
    Atom.to_string(val) =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end
  
  defp vertex_id(identifier) do
    case identifier do
      %{vertex: vertex} -> vertex._id
      _ -> identifier
    end
  end
  
  defp parameterize(var, js, node_module) do
    case var do
      nil -> js
      var ->
        # register_var(var, node_module)
        "var #{Atom.to_string(var)} = #{js}._id"
    end
  end
  
  # defp register_var(var, node_module) do
  #   vars = Process.get(:vars, %{})
  #     |> Map.put(var, node_module)
  #   Process.put(:vars, vars)
  # end
      
  defp jsify(map) when is_map(map) do
    do_encode(map)
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
  defp jsify(value), do: value
  
  defp fnwrap(js, params\\[]) do
    wrap(js, "function(#{Enum.join(params, ",")}){", "}")
  end

  defp wrap(js, left, right) do
    case js do
      "" -> ""
      js -> left <> js <> right
    end
  end

  defp merge(transaction, addition) do
    Map.from_struct(transaction)
    |> update_in([:action], &(&1 ++ List.wrap(addition.action)))
    |> update_in([:collections, :read], &(&1 ++ Map.get(addition.collections, :read, []) |> Enum.uniq))
    |> update_in([:collections, :write], &(&1 ++ Map.get(addition.collections, :write, []) |> Enum.uniq))
    |> update_in([:params], &Map.merge(&1, addition.params || %{}))
    |> put_in([:return], addition.return)
    |> to_transaction
  end
  
  defp to_transaction(data) do
    struct(Transaction, data)
  end

  defp to_result(data, return_type, database) when is_list(data) do
    data
    |> Enum.map(&to_result(&1, return_type, database))
  end
  defp to_result(nil, _return_type, _database) do
    nil
  end
  defp to_result(data, nil, _database) do
    data
  end
  defp to_result(data, {return_type, param}, database) do
    to_result(%{vertex: Vertex.vertex(%Vertex{_id: Map.get(data, param)}, database)}, return_type, database)
  end
  defp to_result(data, return_type, _database) do
    struct(return_type, data)
  end
  
end