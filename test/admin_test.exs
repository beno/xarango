defmodule AdminTest do
  use ExUnit.Case
  doctest Xarango

  alias Xarango.Admin
  
  test "version" do
    config = Admin.version
    assert String.length(config.server) > 0
    assert String.length(config.version) > 0
    assert is_nil(config.details)
  end
  
  test "version details" do
    config = Admin.version(details: true)
    assert String.length(config.server) > 0
    assert String.length(config.version) > 0
    refute is_nil(config.details)
  end
  
  test "flush wal" do
    result = Admin.flush_wal
    refute result[:error]
  end
  
  test "wal props" do
    wal = Admin.wal_properties
    assert wal.logfileSize > 0
  end
  
  test "set wal props" do
    wal = %Xarango.WriteAheadLog{allowOversizeEntries: true}
    wal = Admin.set_wal_properties(wal)
    assert wal.allowOversizeEntries == true
    wal = %Xarango.WriteAheadLog{allowOversizeEntries: false}
    wal = Admin.set_wal_properties(wal)
    assert wal.allowOversizeEntries == false
  end
  
end
