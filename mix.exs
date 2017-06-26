defmodule Xarango.Mixfile do
  use Mix.Project

  def project do
    [
     app: :xarango,
     version: "0.6.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: description(),
     package: package()
    ]
  end

  def application do
    [applications: [:logger, :httpoison, :poison]]
  end

  defp description do
    """
    Client library for ArangoDB.
    """
  end

  defp package do
    [
     name: :xarango,
     files: ["lib", "mix.exs", "README*", "LICENSE"],
     maintainers: ["Michel Benevento"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/beno/xarango"}
    ]
  end

  defp deps do
    [
      {:httpoison, "> 0.0.0"},
      {:poison, "> 0.0.0"},
      {:faker, "> 0.0.0", only: :test},
      {:ex_doc, "> 0.0.0", only: :dev}
    ]
  end
end
