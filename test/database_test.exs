defmodule DatabaseTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper
  
  alias Xarango.Database

  test "lists the databases" do
    list = Database.databases
    assert is_list(list)
    assert length(list) >= 1
  end
  
  test "lists user databases" do
    list = Database.user_databases
    assert is_list(list)
    assert length(list) >= 1
  end
  
  test "database info" do
    db = Database.database(%Database{name: "_system"})
    assert db.name == "_system"
  end
  
  test "create database" do
    source = database_()
    db = Database.create(source)
    Database.destroy(db)
    assert db.name == source.name
  end
  
  test "create database with users" do
    users = [%Xarango.User{username: "foo", passw: "bar", active: true}]
    source = %Database{ database_() | users: users}
    db = Database.create(source)
    Database.destroy(db)
    assert db.name == source.name
  end
  
  test "delete database" do
    db = Database.create(database_())
    result = Database.destroy(db)
    assert result[:result] == true
    assert result[:error] == false
  end



end
