defmodule DenoEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :deno_ex,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      compilers: Mix.compilers() ++ [:deno]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:octo_fetch, "~> 0.3.0"},
      {:recon_ex, "~> 0.9.1", only: [:dev]},
      {:nimble_options, "~> 1.0.2"},
      {:ex_doc, "~> 0.29.4"},
      {:erlexec, "~> 2.0.2"}
    ]
  end
end
