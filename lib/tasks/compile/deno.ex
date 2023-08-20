defmodule Mix.Tasks.Compile.Deno do
  @moduledoc """
  Installs Deno as part of the build process

  See `DenoEx` for information on configuring the location of
  deno installation.
  """
  use Mix.Task.Compiler

  @impl Mix.Task.Compiler
  def run(_) do
    deno_path = Path.join(DenoEx.executable_path(), "deno")

    if File.exists?(deno_path) do
      {:noop, []}
    else
      if function_exported?(Mix, :ensure_application!, 1) do
        Mix.ensure_application!(:inets)
        Mix.ensure_application!(:ssl)
      end

      _ = DenoEx.DenoDownloader.install(DenoEx.executable_path(), 0o770)

      if File.exists?(deno_path) do
        {:ok, ["Deno installation complete"]}
      else
        {:error, ["Deno failed to install"]}
      end
    end
  end
end
