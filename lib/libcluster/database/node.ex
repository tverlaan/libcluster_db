defmodule Cluster.Strategy.Database.Node do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "libcluster_nodes" do
    field(:name, :string, primary_key: true)
  end

  def changeset(node, params) do
    node
    |> cast(params, [:name])
    |> unique_constraint(:name)
  end
end
