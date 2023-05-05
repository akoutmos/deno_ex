defmodule Mix.Tasks.DenoEx.Install do
  use Mix.Task

  @shortdoc "Installs Deno"

  @options_schema [
    path: [
      type: :string,
      default: DenoEx.executable_location(),
      doc: "The path to install deno."
    ],
    chmod: [
      type: :string,
      default: "770",
      doc: "The permissions that will be set on the deno binary. In octal format."
    ]
  ]

  @moduledoc """
  A mix task that installs Deno into your project.

  # Usage

    > mix deno.install

  # Options

    #{NimbleOptions.docs(@options_schema)}
  """

  @impl true
  def run(args) do
    {:ok, options} =
      args
      |> OptionParser.parse(aliases: [p: :path], strict: [path: :string, chmod: :string])
      |> elem(0)
      |> NimbleOptions.validate(@options_schema)

    Mix.shell().info("Installing Deno to #{options[:path]} and setting permissions to #{options[:chmod]}")

    {chmod, _} = Integer.parse(options[:chmod], 8)
    DenoEx.DenoDownloader.install(options[:path], chmod)
  end
end
