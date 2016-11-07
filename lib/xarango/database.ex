defmodule Xarango.Database do
  
  alias Xarango.Database
  import Xarango.Client
  use Xarango.URI, prefix: "database"
  
  defstruct [:id, :name, :isSystem, :path, :users]
  
  def databases() do
    url("", system)
    |> get
    |> Enum.map(fn name -> struct(Database, [name: name])  end)
  end
  
  def user_databases() do
    url("user", system)
    |> get
    |> Map.get(:result)
    |> Enum.map(&to_database(%{name: &1}))
  end
  
  def database(database) do
    url("current", database)
    |> get
    |> to_database
  end
  
  def create(database) do
    url("", system)
    |> post(database)
    database
  end
  
  def destroy(database) do
    url(database.name, system)
    |> delete
  end
  
  def ensure(database) do
    try do
      database(database)
    rescue
      Xarango.Error -> create(database)
    end
  end
  
  def default do
    %Database{name: Application.get_env(:xarango, :db)[:database]}
  end
  
  def system do
    %Database{name: "_system"}
  end

  
  defp to_database(data) do
    struct(Database, Map.get(data, :result, data))
  end
  

  # defp url(path, options\\[]) do
  #   Xarango.Client.url("/_api/database/#{path}", options)
  # end
  # 
  # defp db_url(database, path, options\\[]) do
  #   Xarango.Client.url("/_db/#{database.name}/_api/database/#{path}", options)
  # end


  
  
end