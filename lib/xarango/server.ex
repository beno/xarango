defmodule Xarango.Server do

  defstruct [:server, :database, :version, :username, :password, :details]
  
  import Xarango.Client

  def server do
    case Application.get_env(:xarango, :db) do
      nil -> raise Xarango.Error, message: "no configuration set"
      config -> to_server(config)
    end
  end
  
  #details
  def version(options\\[]) do
    url("/_api/version", options)
    |> get
    |> to_server
  end
  
  #waitForSync, waitForCollector
  def flush_wal(options\\[]) do
    url("/_admin/wal/flush", options)
    |> put
  end
  
  def set_wal_properties(wal, options\\[]) do
    url("/_admin/wal/properties", options)
    |> put(wal)
    |> to_wal
  end
  
  def wal_properties(options\\[]) do
    url("/_admin/wal/properties", options)
    |> get
    |> to_wal
  end
  
  defp to_server(data) do
    struct(Xarango.Server, data)
  end
  
  defp to_wal(data) do
    struct(Xarango.WriteAheadLog, data)
  end
  
  defp url(path, options) do
    Xarango.Client._url(path, options)
  end

end

defmodule Xarango.WriteAheadLog do

  defstruct [:allowOversizeEntries, :logfileSize, :historicLogfiles, :reserveLogfiles, 
    :throttleWait, :throttleWhenPending, :syncInterval]

end