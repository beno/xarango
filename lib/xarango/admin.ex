defmodule Xarango.Admin do
  
  alias Xarango.Client
  
  #details
  def version(options\\[]) do
    url("/_api/version", options)
    |> Client.get
    |> to_config
  end
  
  #waitForSync, waitForCollector
  def flush_wal(options\\[]) do
    url("/_admin/wal/flush", options)
    |> Client.put
  end
  
  def set_wal_properties(wal, options\\[]) do
    url("/_admin/wal/properties", options)
    |> Client.put(wal)
    |> to_wal
  end
  
  def wal_properties(options\\[]) do
    url("/_admin/wal/properties", options)
    |> Client.get
    |> to_wal
  end

  
  defp to_config(data) do
    struct(Xarango.Config, data)
  end
  
  defp to_wal(data) do
    struct(Xarango.WriteAheadLog, data)
  end

  
  defp url(path, options) do
    Xarango.Connection.url(path, options)
  end
  
end

defmodule Xarango.Config do
  
  defstruct [:version, :server, :details]
  
end

defmodule Xarango.WriteAheadLog do

  defstruct [:allowOversizeEntries, :logfileSize, :historicLogfiles, :reserveLogfiles, :throttleWait, :throttleWhenPending, :syncInterval]

end
