defmodule SqlcxTest do
  use ExUnit.Case

  @shared_cache 'file::memory:?cache=shared'
  @test_db [File.cwd!, "test", "test.db"] |> Path.join

  setup_all do
    {:ok, db} = Sqlcx.open(@shared_cache)
    on_exit fn ->
      Sqlcx.close(db)
    end
    {:ok, golf_db: TestDatabase.init(db)}
  end

  test "encryption" do
    try do
      {:ok, db} = Sqlcx.open_encrypted(@test_db, <<1,2,0,3,4>>)
      :ok = Sqlcx.exec(db, "CREATE TABLE test(a INT, b TEXT)")
      :ok = Sqlcx.rekey(db, "abcd")
      :ok = Sqlcx.close(db)
      {:ok, _} = Sqlcx.open_encrypted(@test_db, "abcd")
    after
      File.rm!(@test_db)
    end
  end

  test "server basic query" do
    {:ok, conn} = Sqlcx.Server.start_link({@shared_cache, nil})
    {:ok, [row]} = Sqlcx.Server.query(conn, "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318107}}, updated_at: {{2013,09,06},{22,29,36,610911}}, type: nil]
    Sqlcx.Server.stop(conn)
  end

  test "server basic query by name" do
    {:ok, _} = Sqlcx.Server.start_link({@shared_cache, nil}, name: :sql)
    {:ok, [row]} = Sqlcx.Server.query(:sql, "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318107}}, updated_at: {{2013,09,06},{22,29,36,610911}}, type: nil]
    Sqlcx.Server.stop(:sql)
  end

  test "that it returns an error for a bad query" do
    {:ok, _} = Sqlcx.Server.start_link({":memory:", nil}, name: :bad_create)
    assert {:error, {:sqlite_error, 'near "WHAT": syntax error'}} == Sqlcx.Server.query(:bad_create, "CREATE WHAT")
  end

  test "a basic query returns a list of keyword lists", context do
    {:ok, [row]} = context[:golf_db] |> Sqlcx.query("SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318107}}, updated_at: {{2013,09,06},{22,29,36,610911}}, type: nil]
  end

  test "a basic query returns a list of maps when into: %{} is given", context do
    {:ok, [row]} = context[:golf_db] |> Sqlcx.query("SELECT * FROM players ORDER BY id LIMIT 1", into: %{})
    assert row == %{id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318107}}, updated_at: {{2013,09,06},{22,29,36,610911}}, type: nil}
  end

  test "with_db" do
    {:ok, [row]} = Sqlcx.with_db(@shared_cache, fn(db) ->
      Sqlcx.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
    end)

    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318107}}, updated_at: {{2013,09,06},{22,29,36,610911}}, type: nil]
  end

  test "table creation works as expected" do
    {:ok, [row]} = Sqlcx.with_db(":memory:", fn(db) ->
      Sqlcx.create_table(db, :users, id: {:integer, [:primary_key, :not_null]}, name: :text)
      Sqlcx.query(db, "SELECT * FROM sqlite_master", into: %{})
    end)

    assert row.type == "table"
    assert row.name == "users"
    assert row.tbl_name == "users"
    assert row.sql == "CREATE TABLE \"users\" (\"id\" integer PRIMARY KEY NOT NULL, \"name\" text )"
  end

  test "a parameterized query", context do
    {:ok, [row]} = context[:golf_db] |> Sqlcx.query("SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"])
    assert row == [id: 25, name: "Slothstronauts"]
  end

  test "a parameterized query into %{}", context do
    {:ok, [row]} = context[:golf_db] |> Sqlcx.query("SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"], into: %{})
    assert row == %{id: 25, name: "Slothstronauts"}
  end

  test "exec" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
    :ok = Sqlcx.exec(db, "INSERT INTO t VALUES (1, 2, 3)")
    {:ok, [row]} = Sqlcx.query(db, "SELECT * FROM t LIMIT 1")
    assert row == [a: 1, b: 2, c: 3]
    Sqlcx.close(db)
  end

  test "it handles queries with no columns" do
    {:ok, db} = Sqlcx.open(':memory:')
    assert {:ok, []} == Sqlcx.query(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
    Sqlcx.close(db)
  end

  test "it handles different cases of column types" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (inserted_at DATETIME, updated_at DateTime)")
    :ok = Sqlcx.exec(db, "INSERT INTO t VALUES ('2012-10-14 05:46:28.312941', '2012-10-14 05:46:35.758815')")
    {:ok, [row]} = Sqlcx.query(db, "SELECT inserted_at, updated_at FROM t")
    assert row[:inserted_at] == {{2012, 10, 14}, {5, 46, 28, 312941}}
    assert row[:updated_at] == {{2012, 10, 14}, {5, 46, 35, 758815}}
  end

  test "it inserts nil" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (a INTEGER)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?1)", bind: [nil])
    {:ok, [row]} = Sqlcx.query(db, "SELECT a FROM t")
    assert row[:a] == nil
  end

  test "it inserts boolean values" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (id INTEGER, a BOOLEAN)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?1, ?2)", bind: [1, true])
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?1, ?2)", bind: [2, false])
    {:ok, [row1, row2]} = Sqlcx.query(db, "SELECT a FROM t ORDER BY id")
    assert row1[:a] == true
    assert row2[:a] == false
  end

  test "it inserts Erlang date types" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (d DATE)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?)", bind: [{1985, 10, 26}])
    {:ok, [row]} = Sqlcx.query(db, "SELECT d FROM t")
    assert row[:d] == {1985, 10, 26}
  end

  test "it inserts Elixir time types" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (t TIME)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?)", bind: [{1, 20, 0, 666}])
    {:ok, [row]} = Sqlcx.query(db, "SELECT t FROM t")
    assert row[:t] == {1, 20, 0, 666}
  end

  test "it inserts Erlang datetime tuples" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (dt DATETIME)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?)", bind: [{{1985, 10, 26}, {1, 20, 0, 666}}])
    {:ok, [row]} = Sqlcx.query(db, "SELECT dt FROM t")
    assert row[:dt] == {{1985, 10, 26}, {1, 20, 0, 666}}
  end

  test "query! returns data" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (num INTEGER)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?)", bind: [1])
    results = Sqlcx.query!(db, "SELECT num from t")
    assert results == [[num: 1]]
  end

  test "query! throws on error" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (num INTEGER)")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?)", bind: [1])
    assert_raise Sqlcx.QueryError, "Query failed: {:sqlite_error, 'no such column: nope'}", fn ->
      [_res] = Sqlcx.query!(db, "SELECT nope from t")
    end
  end

  test "server query times out" do
    {:ok, conn} = Sqlcx.Server.start_link({":memory:", nil})
    assert match?({:timeout, _},
      catch_exit(Sqlcx.Server.query(conn, "SELECT * FROM sqlite_master", timeout: 0)))
    receive do # wait for the timed-out message
      msg -> msg
    end
  end

  test "decimal types" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (f DECIMAL)")
    d = Decimal.new(1.123)
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?)", bind: [d])
    {:ok, [row]} = Sqlcx.query(db, "SELECT f FROM t")
    assert row[:f] == d
  end

  test "decimal types with scale and precision" do
    {:ok, db} = Sqlcx.open(":memory:")
    :ok = Sqlcx.exec(db, "CREATE TABLE t (id INTEGER, f DECIMAL(3,2))")
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?,?)", bind: [1, Decimal.new(1.123)])
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?,?)", bind: [2, Decimal.new(244.37)])
    {:ok, []} = Sqlcx.query(db, "INSERT INTO t VALUES (?,?)", bind: [3, Decimal.new(1997)])

    # results should be truncated to the appropriate precision and scale:
    Sqlcx.query!(db, "SELECT f FROM t ORDER BY id")
    |> Enum.map(fn row -> row[:f] end)
    |> Enum.zip([Decimal.new(1.12), Decimal.new(244), Decimal.new(1990)])
    |> Enum.each(fn {res, ans} -> assert Decimal.equal?(res, ans) end)
  end
end
