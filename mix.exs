defmodule Pitch.MixProject do
  use Mix.Project

  def project do
    [
      app: :pitch,
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
      {:nimble_csv, "~> 1.1"},
      {:finch, "~> 0.9.0"},
      {:jason, "~> 1.2"},
      {:retry, "~> 0.15.0"}
    ]
  end
end
