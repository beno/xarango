defmodule Xarango.User do
  
  defstruct [:user, :username, :passw, :passwd, :active, :extra, :changePassword]
  
  alias Xarango.Client
  alias Xarango.User

  def databases do
    Xarango.Database.user_databases
  end
  
  def user(user) do
    url(user.user)
    |> Client.get
    |> to_user
  end
  
  def users do
    url("")
    |> Client.get
    |> Map.get(:result)
    |> Enum.map(&to_user(&1))
  end
  
  def create(%User{user: u, passw: p} = user) when is_binary(u) and is_binary(p) do
    url("")
    |> Client.post(user)
    |> to_user
  end
  
  def create(_) do
    raise "username and/or password not set"
  end
  
  #uses :passwd instead of :passw !?
  def replace(user) do
    url(user.user)
    |> Client.put(Map.take(user, [:passwd, :active, :extra]))
    |> to_user
  end
  
  def update(user) do
    url(user.user)
    |> Client.patch(Map.take(user, [:passwd, :active, :extra]))
    |> to_user
  end

  
  def destroy(user) do
    url(user.user)
    |> Client.delete
  end
  
  def grant_access(user, database) do
    url("#{user.user}/database/#{database.name}")
    |> Client.put(%{grant: "rw"})
  end
  
  def revoke_access(user, database) do
    url("#{user.user}/database/#{database.name}")
    |> Client.put(%{grant: "none"})
  end

  
  defp to_user(data) do
    struct(User, data)
  end
  
  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/user/#{path}", options)
  end
  
end