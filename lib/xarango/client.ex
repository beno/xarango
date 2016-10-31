defmodule Xarango.Client do
    
  [:get, :post, :put, :patch, :delete, :head, :options]
  |> Enum.map(fn method ->
    def unquote(method)(url, body\\"") do
      case do_request(unquote(method), url, body) do
        {:ok, body} -> body
        {:error, error} -> do_error error[:errorMessage]
      end
    end
  end)
  
  def _url(path, options\\[]) do
    Xarango.Server.server.server <> path <> query_params(options)
  end
  
  def credentials do
    case Xarango.Server.server do
      %{username: nil} -> do_error "missing database username, set ARANGO_USER environment variable"
      %{password: nil} -> do_error "missing database password, set ARANGO_PASSWORD environment variable"
      %{username: username, password: password} -> {username, password}
      _ -> do_error "database credentials invalid, update `xarango.db` app config"
    end
  end
  
  def headers do
    {username, password} = credentials
    auth_header = "Basic " <> Base.encode64("#{username}:#{password}")
    ["Accept": "*/*", "Authorization": auth_header]
    #x-arango-async
  end
  
  defp query_params(options) do
    case URI.encode_query(options) do
      "" -> ""
      params -> "?" <> params
    end
  end
  
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
    case HTTPoison.request(method, url, body, headers) do
      {:error, %HTTPoison.Error{reason: error}} when is_atom(error)-> raise Xarango.Error, message: Atom.to_string(error)
      {:error, %HTTPoison.Error{reason: error}} when is_binary(error)-> raise Xarango.Error, message: error
      {:error, error} when is_binary(error) -> raise Xarango.Error, message: error
      {:ok, response} ->  do_decode(response)
    end
  end
  
  defp do_decode(response) do
    case response do
      %HTTPoison.Response{status_code: status_code, body: body} when status_code >= 200 and status_code < 300 ->
        {:ok, Poison.decode!(body, keys: :atoms)}
      %HTTPoison.Response{body: body} ->
        {:error, Poison.decode!(body, keys: :atoms)}
      %HTTPoison.Error{reason: reason} -> do_error reason
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

  defp do_error(msg) do
    raise Xarango.Error, message: msg
  end
        
end
