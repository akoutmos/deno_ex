defmodule DenoEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :deno_ex,
      version: project_version(),
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      compilers: Mix.compilers() ++ [:deno],
      name: "DenoEx",
      source_url: "https://github.com/akoutmos/deno_ex",
      homepage_url: "https://hex.pm/packages/deno_ex",
      description: "Run TypeScript & JavaScript files right from Elixir.",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_add_deps: :apps_direct,
        plt_add_apps: [:erlexec, :octo_fetch, :mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: ~w[unmatched_returns error_handling underspecs]a
      ],
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp project_version do
    "VERSION"
    |> File.read!()
    |> String.trim()
  end

  defp package do
    [
      name: "deno_ex",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md VERSION),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/deno_ex",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.svg",
      extras: [
        "README.md",
        "guides/examples/tesseract_ocr.livemd",
        "guides/examples/web_scraper.livemd",
        "VERSION"
      ],
      groups_for_extras: [
        "Example Livebooks": Path.wildcard("guides/examples/*.livemd")
      ]
    ]
  end

  defp deps do
    [
      # Production dependencies
      {:octo_fetch, "~> 0.3.0"},
      {:nimble_options, "~> 1.0.2"},
      {:erlexec, "~> 2.0.2"},

      # Development dependencies
      {:recon_ex, "~> 0.9.1", only: [:dev]},
      {:ex_doc, "~> 0.29.4", only: :dev},
      {:excoveralls, "~> 0.16.1", only: [:test, :dev], runtime: false},
      {:doctor, "~> 0.21.0", only: :dev},
      {:credo, "~> 1.7.0", only: :dev},
      {:dialyxir, "~> 1.3.0", only: :dev, runtime: false},
      {:styler, "~> 0.7.11", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
