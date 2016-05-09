defmodule Sqlcx.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlcx,
     version: "1.1.0",
     elixir: "~> 1.2",
     deps: deps,
     package: package,
     description: """
      A thin Elixir wrapper around esqlcipher
    """]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :esqlcipher]]
  end

  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:esqlcipher, "~> 1.0.0"},
      {:decimal, "~> 1.1.0"},

      {:dialyze, "~> 0.2.0", only: :dev},
      {:earmark, "~> 0.2.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev},
    ]
  end

  defp package do
   [maintainers: ["Felix Kiunke"],
     licenses: ["MIT"],
     links: %{
      github: "https://github.com/FelixKiunke/sqlcx",
      docs: "http://hexdocs.pm/sqlcx"}]
  end
end
