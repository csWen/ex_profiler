defmodule ExProfiler.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_profiler,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExProfiler.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:recon, "~> 2.5"},
      {:mimic, "~> 1.1", only: [:test]}
    ]
  end
end
