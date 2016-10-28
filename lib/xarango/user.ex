defmodule Xarango.User do
  
  defstruct [:user, :username, :passw, :passwd, :active, :extra, :changePassword]
  
  alias Xarango.User
  import Xarango.Client
  use Xarango.URI, prefix: "user"

  def databases do
    Xarango.Database.user_databases
  end
  
  def user(user) do
    url(user.user)
    |> get
    |> to_user
  end
  
  def users do
    url("")
    |> get
    |> Map.get(:result)
    |> Enum.map(&to_user(&1))
  end
  
  def create(%User{user: u, passw: p} = user) when is_binary(u) and is_binary(p) do
    url("")
    |> post(user)
    |> to_user
  end
  
  def create(_) do
    raise Xarango.Error, message: "username and/or password not set"
  end
  
  #uses :passwd instead of :passw !?
  def replace(user) do
    url(user.user)
    |> put(Map.take(user, [:passwd, :active, :extra]))
    |> to_user
  end
  
  def update(user) do
    url(user.user)
    |> patch(Map.take(user, [:passwd, :active, :extra]))
    |> to_user
  end

  def destroy(user) do
    url(user.user)
    |> delete
  end
  
  def grant_access(user, database) do
    url("#{user.user}/database/#{database.name}")
    |> put(%{grant: "rw"})
  end
  
  def revoke_access(user, database) do
    url("#{user.user}/database/#{database.name}")
    |> put(%{grant: "none"})
  end

  defp to_user(data) do
    struct(User, data)
  end
    
end