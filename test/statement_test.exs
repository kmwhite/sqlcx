defmodule StatementTest do
  use ExUnit.Case, async: true
  doctest Sqlcx.Statement

  test "fetch_all! works" do
    {:ok, db} = Sqlcx.open(":memory:")

    result = Sqlcx.Statement.prepare!(db, "PRAGMA user_version;")
             |> Sqlcx.Statement.fetch_all!

    assert result == [[user_version: 0]]
  end
end
