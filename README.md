[![Build Status](https://travis-ci.org/FelixKiunke/sqlcx.png?branch=master)](https://travis-ci.org/FelixKiunke/sqlcx)
[![Inline docs](http://inch-ci.org/github/FelixKiunke/sqlcx.png?branch=master)](http://inch-ci.org/github/FelixKiunke/sqlcx)

Sqlcx (sqlcipher interface for Elixir)
======================================

An Elixir wrapper around [esqlcipher](https://github.com/FelixKiunke/esqlcipher). The main aim here is to provide convenient usage of sqlcipher databases.

Important Note
==============
This is a fork of the 'regular' sqlite variant (sqlitex). It is not finished yet and lots of things might change later on. Proceed with care :)

Updated to 1.0
==============

With the 1.0 release we made just a single breaking change. `Sqlcx.Query.query` previously returned just the raw query results on success and `{:error, reason}` on failure.
This has been bothering us for a while so we changed it in 1.0 to return `{:ok, results}` on sucess and `{:error, reason}` on failure.
This should make it easier to pattern match on. The `Sqlcx.Query.query!` function has kept its same functionality of returning bare results on success and raising an error on failure.

Usage
=====

The simple way to use Sqlcx is just to open a database and run a query

```elixir
Sqlcx.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
  Sqlcx.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
end)
# => [[id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]]

Sqlcx.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
  Sqlcx.query(db, "SELECT * FROM players ORDER BY id LIMIT 1", into: %{})
end)
# => [%{id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil}]
```

If you want to keep the database open during the lifetime of your project you can use the `Sqlcx.Server` GenServer module.
Here's a sample from a phoenix projects main supervisor definition.
```elixir
children = [
      # Start the endpoint when the application starts
      worker(Golf.Endpoint, []),

      worker(Sqlcx.Server, ['golf.sqlite3', [name: Sqlcx.Server]])
    ]
```

Now that the GenServer is running you can make queries via
```elixir
Sqlcx.Server.query(Sqlcx.Server,
                     "SELECT g.id, g.course_id, g.played_at, c.name AS course
                      FROM games AS g
                      INNER JOIN courses AS c ON g.course_id = c.id
                      ORDER BY g.played_at DESC LIMIT 10")
```

Plans
=====

I am building this package as an attempt to learn more about Elixir and I'll be adding features only as I need them.

I would love to get any feedback I can on how other people might want to use SQlite with Elixir.
