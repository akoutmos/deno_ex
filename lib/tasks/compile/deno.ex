defmodule Mix.Tasks.Compile.Deno do
  @moduledoc """
  Installs Deno as part of the build process

  See `DenoEx` for information on configuring the location of
  deno installation.
  """
  use Mix.Task.Compiler

  def run(_) do
    deno_path = Path.join(DenoEx.executable_location(), "deno")

    if File.exists?(deno_path) do
      {:noop, []}
    else
      DenoEx.DenoDownloader.install(DenoEx.executable_location(), 0o770)

      if File.exists?(deno_path) do
        {:ok, ["Deno installation complete"]}
      else
        {:error, ["Deno failed to install"]}
      end
    end
  end
end
