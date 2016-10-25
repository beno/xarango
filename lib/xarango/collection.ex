defmodule Xarango.Collection do
  defstruct [:id, :journalSize, :replicationFactor, :keyOptions, :name, :waitForSync, 
      :doCompact, :isVolatile, :shardKeys, :numberOfShards, :isSystem, :type, :indexBuckets, :status, :error,  :count, :figures, :revision, :checksum]
  
  alias Xarango.Collection
  alias Xarango.Client
  
  def collections(database\\nil) do
    url("", database)
    |> Client.get
    |> Map.get(:result)
    |> Enum.map(&struct(Collection, &1))
  end

  def collection(collection, database\\nil) do
    url("#{collection.name}", database)
    |> Client.get
    |> parse_coll
  end
    
  def properties(collection, database\\nil) do
    url("#{collection.name}/properties", database)
    |> Client.get
    |> parse_coll
  end
  
  def count(collection, database\\nil) do
    url("#{collection.name}/count", database)
    |> Client.get
    |> parse_coll
  end
  
  def figures(collection, database\\nil) do
    url("#{collection.name}/figures", database)
    |> Client.get
    |> parse_coll
  end
  
  def revision(collection, database\\nil) do
    url("#{collection.name}/revision", database)
    |> Client.get
    |> parse_coll
  end
  
  def checksum(collection, database\\nil) do
    url("#{collection.name}/checksum", database)
    |> Client.get
    |> parse_coll
  end
  
  def create(collection, database\\nil) do
    url("", database)
    |> Client.post(collection)
    |> parse_coll
  end
  
  def destroy(collection, database\\nil) do
    url(collection.name, database)
    |> Client.delete
  end
  
  def __destroy_all do
    collections
    |> Enum.reject(&Map.get(&1, :isSystem))
    |> Enum.each(&destroy(&1))
  end
  
  defp url(path, database\\nil) do
    case database do
      nil -> "/_api/collection/#{path}"
      db -> "/_db/#{db.name}/_api/collection/#{path}"
    end
    |> Xarango.Connection.url
  end
  
  defp parse_coll(coll) do
    struct(Collection, coll)
  end
end

