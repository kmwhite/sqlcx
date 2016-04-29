defmodule Sqlcx.Query do
  alias Sqlcx.Statement

  @doc """
  Runs a query and returns the results.

  ## Parameters

  * `db` - A sqlcipher database.
  * `sql` - The query to run as a string.
  * `opts` - Options to pass into the query.  See below for details.

  ## Options

  * `bind` - If your query has parameters in it, you should provide the options
    to bind as a list.
  * `into` - The collection to put results into.  This defaults to a list.

  ## Returns
  * [results...] on success
  * {:error, _} on failure.
  """

  @spec query(Sqlcx.connection, String.t | char_list) :: [ [] ] | Sqlcx.sqlite_error
  @spec query(Sqlcx.connection, String.t | char_list, [bind: [], into: Enum.t]) :: [ Enum.t ] | Sqlcx.sqlite_error
  def query(db, sql, opts \\ []) do
    with {:ok, db} <- Statement.prepare(db, sql),
         {:ok, db} <- Statement.bind_values(db, Dict.get(opts, :bind, [])),
         {:ok, res} <- Statement.fetch_all(db, Dict.get(opts, :into, [])),
    do: {:ok, res}
  end

  @doc """
  Same as `query/3` but raises a Sqlcx.QueryError on error.

  Returns the results otherwise.
  """
  @spec query!(Sqlcx.connection, String.t | char_list) :: [ [] ]
  @spec query!(Sqlcx.connection, String.t | char_list, [bind: [], into: Enum.t]) :: [ Enum.t ]
  def query!(db, sql, opts \\ []) do
    case query(db, sql, opts) do
      {:error, reason} -> raise Sqlcx.QueryError, reason: reason
      {:ok, results} -> results
    end
  end
end
