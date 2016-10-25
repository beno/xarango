defmodule UserTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.User
  alias Xarango.Database
  # 
  # setup do
  #   on_exit fn ->
  #     Collection.__destroy_all
  #   end
  # end
  
  test "create user" do
    source = user_
    user = User.create(source)
    User.destroy(user)
    assert user.active == true
    assert user.user == source.user
  end
  
  test "get user" do
    source = user_
    user = User.create(source)
    user = User.user(user)
    User.destroy(user)
    assert user.active == true
    assert user.user == source.user
  end

  test "list users" do
    users = User.users
    assert is_list(users)
    assert length(users) > 0
  end
  
  test "replace user" do
    source = user_
    user = User.create(source)
    new_user = %User{ user | active: false}
    user = User.replace(new_user)
    User.destroy(user)
    assert user.active == false
    assert user.user == source.user
  end
  
  test "update user" do
    source = %User{ user_ | extra: %{jabba: "dabba"} }
    user = User.create(source)
    new_user = %User{ user | extra: %{foo: "bar"} }
    user = User.update(new_user)
    User.destroy(user)
    assert user.extra == Map.merge(source.extra, new_user.extra)
  end

  test "grant db access" do
    db = Database.create(database_)
    user = User.create(user_)
    result = User.grant_access(user, db)
    assert Map.get(result, String.to_atom(db.name)) == "rw"
    User.destroy(user)
    Database.destroy(db)
  end
  
  test "revoke db access" do
    db = Database.create(database_)
    user = User.create(user_)
    result = User.revoke_access(user, db)
    User.destroy(user)
    Database.destroy(db)
    assert Map.get(result, String.to_atom(db.name)) == "none"
  end
  
  test "raise user" do
    assert_raise RuntimeError, "username and/or password not set", fn ->
      User.create(%User{})
    end
  end

  test "destroy user" do
    source = user_
    user = User.create(source)
    result = User.destroy(user)
    refute result[:error]
  end

  # defp _collection do
  #   Collection.create(collection_) |> Collection.collection
  # end
  
end
