defmodule LibclusterDb do
  @moduledoc """
  Configuration can be found in `Cluster.Strategy.Database`
  """

  defdelegate get_nodes(), to: Cluster.Strategy.Database
  defdelegate connect_node(nodename), to: Cluster.Strategy.Database
  defdelegate disconnect_node(nodename), to: Cluster.Strategy.Database
end
