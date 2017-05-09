defmodule Xarango.Client do

  alias Xarango.Util

  [:get, :post, :put, :patch, :delete, :head, :options]
  |> Enum.map(fn method ->
    def unquote(method)(url, body\\"") do
      case do_request(unquote(method), url, body) do
        {:ok, body} -> body
        {:error, error} -> Util.do_error error[:errorMessage]
      end
    end
  end)

  def _url(path, options\\[]) do
    Xarango.Server.server.server <> path <> query_params(options)
  end

  def credentials do
    case Xarango.Server.server do
      %{username: nil} -> Util.do_error "missing database username, set ARANGO_USER environment variable"
      %{password: nil} -> Util.do_error "missing database password, set ARANGO_PASSWORD environment variable"
      %{username: username, password: password} -> {username, password}
      _ -> Util.do_error "database credentials invalid, update `xarango.db` app config"
    end
  end

  def headers do
    {username, password} = credentials()
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
      |> Enum.map(&Util.do_encode(&1))
      |> Poison.encode!
    do_request(method, url, body)
  end

  defp do_request(method, url, body) when is_map(body) do
    body = body
      |> Util.do_encode
      |> Poison.encode!
    do_request(method, url, body)
  end

  defp do_request(method, url, body) when is_binary(body) do
    case HTTPoison.request(method, url, body, headers()) do
      {:error, %HTTPoison.Error{reason: error}} when is_atom(error)-> raise Xarango.Error, message: Atom.to_string(error)
      {:error, %HTTPoison.Error{reason: error}} when is_binary(error)-> raise Xarango.Error, message: error
      {:error, error} when is_binary(error) -> raise Xarango.Error, message: error
      {:ok, response} ->  Util.do_decode(response)
    end
  end

  def decode_data(data, into), do: Util.decode_data(data, into)

end
