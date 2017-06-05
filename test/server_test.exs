defmodule ServerTest do
  use ExUnit.Case
  doctest Xarango

  alias Xarango.Server

  test "version" do
    version = Server.version
    assert String.length(version.server) > 0
    assert String.length(version.version) > 0
    assert is_nil(version.details)
  end

  test "version details" do
    version = Server.version(details: true)
    assert String.length(version.server) > 0
    assert String.length(version.version) > 0
    refute is_nil(version.details)
  end

  test "flush wal" do
    result = Server.flush_wal
    refute result[:error]
  end

  test "wal props" do
    wal = Server.wal_properties
    assert wal.logfileSize > 0
  end

  test "set wal props" do
    wal = %Xarango.WriteAheadLog{allowOversizeEntries: true}
    wal = Server.set_wal_properties(wal)
    assert wal.allowOversizeEntries == true
    wal = %Xarango.WriteAheadLog{allowOversizeEntries: false}
    wal = Server.set_wal_properties(wal)
    assert wal.allowOversizeEntries == false
  end

end
