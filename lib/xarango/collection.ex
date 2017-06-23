defmodule Xarango.Collection do
  defstruct [:id, :journalSize, :replicationFactor, :keyOptions, :name, :waitForSync,
      :doCompact, :isVolatile, :shardKeys, :numberOfShards, :isSystem, :type, :indexBuckets, :status, :error,  :count, :figures, :revision, :checksum]

  alias Xarango.Collection
  alias Xarango.Index
  import Xarango.Client
  use Xarango.URI, prefix: "collection"

  def collections(database\\nil) do
    url("", database)
    |> get
    |> Map.get(:result)
    |> Enum.map(&to_collection(&1))
  end

  def collection(collection, database\\nil) do
    url(name(collection), database)
    |> get
    |> to_collection
  end

  def properties(collection, database\\nil) do
    url("#{name(collection)}/properties", database)
    |> get
    |> to_collection
  end

  def count(collection, database\\nil) do
    url("#{name(collection)}/count", database)
    |> get
    |> to_collection
  end

  def figures(collection, database\\nil) do
    url("#{name(collection)}/figures", database)
    |> get
    |> to_collection
  end

  def revision(collection, database\\nil) do
    url("#{name(collection)}/revision", database)
    |> get
    |> to_collection
  end

  def checksum(collection, database\\nil) do
    url("#{name(collection)}/checksum", database)
    |> get
    |> to_collection
  end

  def create(collection, database\\nil) do
    url("", database)
    |> post(collection)
    |> to_collection
  end

  def destroy(collection, database\\nil) do
    url(name(collection), database)
    |> delete
  end

  def ensure(collection, database\\nil, indexes\\[]) do
    try do
      collection(collection, database)
    rescue
      Xarango.Error ->
        collection = create(collection, database)
        Enum.each(indexes, &Index.create(&1, name(collection), database))
        collection
    end
  end

  defp name(%{name: name}), do: name
  defp name(%{collection: name}), do: name
  defp name(name) when is_binary(name), do: name

  def __destroy_all(database\\nil) do
    collections(database)
    |> Enum.reject(&Map.get(&1, :isSystem))
    |> Enum.each(&destroy(&1, database))
  end

  defp to_collection(data) do
    struct(Collection, data)
  end
end
