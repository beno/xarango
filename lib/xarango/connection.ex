defmodule Xarango.Connection do

  defstruct [:server, :database, :db_version]
  
  def defaults do
    defaults = Application.get_env(:xarango, :db_defaults)
    struct(Xarango.Connection, defaults)
  end
  
  def url(path, options\\[]) do
    defaults.server <> path <> query_params(options)
  end

  def headers do
    [username: username, password: password] = Application.get_env(:xarango, :db_auth)
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

end