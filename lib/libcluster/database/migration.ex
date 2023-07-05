defmodule Cluster.Strategy.Database.Migration do
  @moduledoc false
  use Ecto.Migration

  def up(_opts \\ []) do
    create_if_not_exists table("libcluster_nodes", primary_key: false) do
      add(:name, :text, null: false, primary_key: true)
    end

    :ok
  end

  def down(_opts \\ []) do
    drop_if_exists(table("libcluster_nodes"))

    :ok
  end
end
