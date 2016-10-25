defmodule Xarango.Client do
    
  [:get, :post, :put, :patch, :delete, :head, :options]
  |> Enum.map(fn method ->
    def unquote(method)(url, body\\"") do
      case do_request(unquote(method), url, body) do
        {:ok, body} -> body
        {:error, error} -> raise error[:errorMessage]
      end
    end
  end)

  # defp do_request(method, url, body\\"")
  
  defp do_request(method, url, body) when is_list(body) do
    body = body
      |> Enum.map(&do_encode(&1))
      |> Poison.encode!
    do_request(method, url, body)
  end

  defp do_request(method, url, body) when is_map(body) do
    body = body
      |> do_encode
      |> Poison.encode!
    do_request(method, url, body)
  end

  defp do_request(method, url, body) when is_binary(body) do
    url = if String.starts_with?(url, "/"), do: Xarango.Connection.url(url), else: url
    case HTTPotion.request(method, url, [body: body, headers: Xarango.Connection.headers]) do
      {:error, error} -> raise error
      response ->  do_decode(response)
    end
  end
  
  defp do_decode(response) do
    case response do
      %HTTPotion.Response{status_code: status_code, body: body} when status_code >= 200 and status_code < 300 ->
        {:ok, Poison.decode!(body, keys: :atoms)}
      %HTTPotion.Response{body: body} ->
        {:error, Poison.decode!(body, keys: :atoms)}
      %HTTPotion.ErrorResponse{message: message} -> raise message
    end
  end
  
  defp do_encode(body) when is_map(body) do
    encode_map(body)
  end
  
  defp do_encode(body) do
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
    |> Enum.reject(fn {_,v} -> v == nil end)
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

        
end
