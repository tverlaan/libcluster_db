# LibclusterDb

This clustering strategy relies on nodes stored in a database.

You can have `libcluster` automatically connect nodes on startup for you by configuring
the strategy like below:

```elixir
config :libcluster,
  topologies: [
    db_config_example: [
      strategy: Cluster.Strategy.Database,
      config: [repo: MyApp.Repo, timeout: 30_000]
    ]
  ]
```

An optional timeout can be specified in the config. This is the timeout that
will be used in the GenServer to connect the nodes. This defaults to
`:infinity` meaning that the connection process will only happen when the
worker is started. Any integer timeout will result in the connection process
being triggered. In the example above, it has been configured for 30 seconds.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `libcluster_db` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:libcluster_db, "~> 0.2.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/libcluster_db>.

## Migrate database

```elixir
defmodule MyApp.Repo.Migrations.AddLibClusterDb do
  use Ecto.Migration

  def up do
    Cluster.Strategy.Database.Migration.up()
  end

  def down do
    Cluster.Strategy.Database.Migration.down()
  end
end
```
