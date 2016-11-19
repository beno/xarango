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

end