defmodule Cluster.Strategy.Database do
  @moduledoc """
  This clustering strategy relies on nodes stored in a database.

  You can have `libcluster` automatically connect nodes on startup for you by configuring
  the strategy like below:

      config :libcluster,
        topologies: [
          db_config_example: [
            strategy: Cluster.Strategy.Database,
            config: [repo: MyApp.Repo, timeout: 30_000]
          ]
        ]

  An optional timeout can be specified in the config. This is the timeout that
  will be used in the GenServer to connect the nodes. This defaults to
  `:infinity` meaning that the connection process will only happen when the
  worker is started. Any integer timeout will result in the connection process
  being triggered. In the example above, it has been configured for 30 seconds.
  """
  use GenServer
  use Cluster.Strategy
  import Ecto.Query, only: [from: 2]

  alias Cluster.Strategy.State
  alias Cluster.Strategy.Database.Node, as: DbNode

  @doc """
  Get a list of nodes and whether they're connected or not
  """
  def get_nodes() do
    node_list = Node.list()

    GenServer.call(__MODULE__, :node_list)
    |> Enum.map(fn node -> %{name: node, connected: node in node_list} end)
  end

  @doc """
  Add a node to the database for libcluster to connect to
  """
  def connect_node(node) when is_atom(node) do
    connect_node(Atom.to_string(node))
  end

  def connect_node(node) do
    GenServer.call(__MODULE__, {:connect_node, node})
  end

  @doc """
  Delete a node from the database for libcluster to disconnect from
  """
  def disconnect_node(node) when is_atom(node) do
    disconnect_node(Atom.to_string(node))
  end

  def disconnect_node(node) do
    GenServer.call(__MODULE__, {:disconnect_node, node})
  end

  def start_link([state]) do
    GenServer.start_link(__MODULE__, [state], name: __MODULE__)
  end

  @impl true
  def init([state]) do
    {:ok, load(%State{state | :meta => MapSet.new()}), configured_timeout(state)}
  end

  @impl true
  def handle_call({:connect_node, nodename}, _from, state) do
    cs = DbNode.changeset(%DbNode{}, %{name: nodename})

    case repo(state).insert(cs) do
      {:ok, _record} -> {:reply, :ok, state, {:continue, :load}}
      other -> {:reply, other, state, configured_timeout(state)}
    end
  end

  def handle_call({:disconnect_node, nodename}, _from, state) do
    with %DbNode{} = node <- repo(state).get(DbNode, nodename),
         {:ok, _record} <- repo(state).delete(node) do
      {:reply, :ok, state, {:continue, :load}}
    else
      nil -> {:reply, :ok, state, configured_timeout(state)}
      other -> {:reply, other, state, configured_timeout(state)}
    end
  end

  def handle_call(:node_list, _from, state) do
    {:reply, get_nodes(state), state, configured_timeout(state)}
  end

  @impl true
  def handle_continue(:load, state) do
    handle_info(:load, state)
  end

  @impl true
  def handle_info(:timeout, state) do
    handle_info(:load, state)
  end

  def handle_info(:load, state) do
    {:noreply, load(state), configured_timeout(state)}
  end

  defp load(
         %State{
           topology: topology,
           connect: connect,
           disconnect: disconnect,
           list_nodes: list_nodes
         } = state
       ) do
    new_nodelist = MapSet.new(get_nodes(state))
    removed = MapSet.difference(state.meta, new_nodelist)

    new_nodelist =
      case Cluster.Strategy.disconnect_nodes(
             topology,
             disconnect,
             list_nodes,
             MapSet.to_list(removed)
           ) do
        :ok ->
          new_nodelist

        {:error, bad_nodes} ->
          # Add back the nodes which should have been removed, but which couldn't be for some reason
          Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
            MapSet.put(acc, n)
          end)
      end

    new_nodelist =
      case Cluster.Strategy.connect_nodes(
             topology,
             connect,
             list_nodes,
             MapSet.to_list(new_nodelist)
           ) do
        :ok ->
          new_nodelist

        {:error, bad_nodes} ->
          # Remove the nodes which should have been added, but couldn't be for some reason
          Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
            MapSet.delete(acc, n)
          end)
      end

    %{state | :meta => new_nodelist}
  end

  defp get_nodes(state) do
    nodes_list =
      from(n in DbNode, select: n.name)
      |> repo(state).all()
      |> Enum.map(&String.to_atom(&1))

    nodes_list -- [Node.self()]
  end

  defp configured_timeout(%State{config: config}) do
    Keyword.get(config, :timeout, :infinity)
  end

  defp repo(%State{config: config}) do
    Keyword.fetch!(config, :repo)
  end
end
