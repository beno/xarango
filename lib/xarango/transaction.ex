defmodule Xarango.Transaction do

  defstruct action: [], params: %{}, collections: %{read: [], write: []}, lockTimeout: 0, waitForSync: false, return: nil, graph: nil

  import Xarango.Client
  alias Xarango.Transaction
  alias Xarango.Edge
  alias Xarango.Vertex
  use Xarango.URI, prefix: "transaction"
  
  def begin(), do: %Transaction{}
  def begin(graph) do
    apply(graph, :ensure, [])
    %Transaction{graph: graph}
  end

  def execute(transaction) do
    case transaction.graph do
      nil -> execute(transaction, nil)
      graph -> execute(transaction, apply(graph, :_database, []))
    end
  end
  def execute(transaction, database) do
    return_type = transaction.return
    transaction = finalize(transaction)
    url("", database)
    |> post(transaction)
    |> Map.get(:result)
    |> to_result(return_type, database)
  end
  
  defp finalize(%{action: action} = transaction) when is_binary(action) do
    %Transaction{transaction | return: nil, graph: nil}
  end
  defp finalize(%{action: action} = transaction) when is_list(action) do
    [return_action | rest] = Enum.reverse(action)
    action = (["return " <> return_action] ++ rest)
      |> Enum.reverse
      |> Enum.join("; ")
    action = fnwrap("var db = require('@arangodb').db;" <> action)
    %Transaction{transaction | action: action, return: nil, graph: nil}
  end
    
  def create(transaction, collection, data, options\\[]) do
    action = "db.#{jsify(collection)}.insert(#{jsify(data)})"
    action = parameterize(options[:var], action, collection)
    merge(transaction, %Transaction{action: action, collections: %{write: [jsify(collection)]}, return: collection})
  end
  
  def update(transaction, collection, data, options\\[]) do
    {id, data} = Map.pop(data, :id)
    action = "db.#{jsify(collection)}.update(#{jsify(id)}, #{jsify(data)})" 
    action = parameterize(options[:var], action, collection)
    merge(transaction, %Transaction{action: action, collections: %{write: [jsify(collection)]}, return: collection})
  end

  def replace(transaction, collection, data, options\\[]) do
    {id, data} = Map.pop(data, :id)
    action = "db.#{jsify(collection)}.replace(#{jsify(id)}, #{jsify(data)})"
    action = parameterize(options[:var], action, collection)
    merge(transaction, %Transaction{action: action, collections: %{write: [jsify(collection)]}, return: collection})
  end

  def ensure(transaction, collection, data, options\\[]) do
    action = "(db.#{jsify(collection)}.firstExample(#{jsify(data)}) || db.#{collection}.insert(#{jsify(data)}))"
    action = parameterize(options[:var], action, collection)
    merge(transaction, %Transaction{action: action, collections: %{write: [jsify(collection)]}, return: collection})
  end
  
  def destroy(transaction, collection, node) do
    action = "(db.#{jsify(collection)}.delete(#{jsify(node.vertex)}))"
    merge(transaction, %Transaction{action: action, collections: %{write: [jsify(collection)]}})
  end
  
  def add(transaction, nil), do: transaction
  def add(transaction, edges) when is_list(edges) do
    Enum.reduce(edges, transaction, fn {from, relationship, to}, transaction ->
      transaction
      |> add(from, relationship, to)
    end)
  end
  def add(transaction, from, relationship, to, data\\nil) do
    edge = %Edge{_from: vertex_id(from),  _to: vertex_id(to), _data: data} |> jsify
    action = "db.#{relationship}.insert(#{edge})"
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
    action = "{_id: #{jsify(var)}}"
    merge(transaction, %Transaction{action: action, return: {type, :_id}})
  end
  def get(transaction, from, relationship, to)  when is_atom(to) do
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
  
  defp parameterize(var, js, _) do
    case var do
      nil -> js
      var ->
        "var #{Atom.to_string(var)} = #{js}._id"
    end
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
  
  defp fnwrap(js, params\\[]) do
    wrap(js, "function(#{Enum.join(params, ",")}){", "}")
  end

  defp wrap(nil, _, _), do: ""
  defp wrap("", _, _), do: ""
  defp wrap(js, left, right), do: left <> js <> right

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
    cond do
      is_module(return_type) ->
        vertex = Vertex.vertex(%Vertex{_id: Map.get(data, param)}, database)
        to_result(%{vertex: vertex}, return_type, database)
      is_atom(return_type) ->
        Edge.edge(%Edge{_id: Map.get(data, param)}, database)
      true -> raise Xarango.Error, message: "Illegal return type"
    end
  end
  defp to_result(data, return_type, _database) do
    struct(return_type, data)
  end
  
end