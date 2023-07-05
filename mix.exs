defmodule LibclusterDb.MixProject do
  use Mix.Project

  def project do
    [
      app: :libcluster_db,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Libcluster DB",
      source_url: "https://github.com/tverlaan/libcluster_db",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      description: "libcluster + database",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/tverlaan/libcluster_db"
      }
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.3.3"},
      {:ecto_sql, "~> 3.10"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
