defmodule Sqlcx do
  @type connection :: {:connection, reference, String.t}
  @type string_or_charlist :: String.t | char_list
  @type sqlite_error :: {:error, {:sqlite_error, char_list}}

  @spec close(connection) :: :ok
  def close(db) do
    :esqlcipher.close(db)
  end

  @spec open(String.t) :: {:ok, connection}
  @spec open(char_list) :: {:ok, connection} | {:error, {atom, char_list}}
  def open(path) when is_binary(path), do: open(String.to_char_list(path))
  def open(path) do
    :esqlcipher.open(path)
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end

  @spec exec(connection, string_or_charlist) :: :ok | sqlite_error
  def exec(db, sql) do
    :esqlcipher.exec(sql, db)
  end

  def query(db, sql, opts \\ []), do: Sqlcx.Query.query(db, sql, opts)
  def query!(db, sql, opts \\ []), do: Sqlcx.Query.query!(db, sql, opts)

  @doc """
  Create a new table `name` where `table_opts` are a list of table constraints
  and `cols` are a keyword list of columns. The following table constraints are
  supported: `:temp` and `:primary_key`. Example:

  **[:temp, {:primary_key, [:id]}]**

  Columns can be passed as:
  * name: :type
  * name: {:type, constraints}

  where constraints is a list of column constraints. The following column constraints
  are supported: `:primary_key`, `:not_null` and `:autoincrement`. Example:

  **id: :integer, name: {:text, [:not_null]}**

  """
  def create_table(db, name, table_opts \\ [], cols) do
    stmt = Sqlcx.SqlBuilder.create_table(name, table_opts, cols)
    exec(db, stmt)
  end
end
