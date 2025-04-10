defmodule GPotion.MixProject do
  use Mix.Project

  def project do
    [
      app: :gpotion,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

 # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:matrex, "~> 0.6"}
      # {:exla, "~> 0.7.1"}
      # {:random, "~> 0.2.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
