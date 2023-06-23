defmodule Mix.Tasks.DenoEx.Deps.Get do
  @moduledoc """
  A mix task for loading deno dependencies cache

  This delegates to `deno cache`
  """
  use Mix.Task

  @shortdoc """
  Creates a lock file of the dependecies for deno
  """

  @requirements ["app.config"]

  @doc false
  @impl Mix.Task
  def run(args) do
    app = Keyword.get(Mix.Project.config(), :app)
    lock_file_path = DenoEx.lock_file_path(app)
    lock_file_dir = Path.dirname(lock_file_path)

    unless File.exists?(lock_file_dir) do
      File.mkdir_p!(lock_file_dir)
    end

    scripts =
      Application.get_env(:deno_ex, :scripts_path)
      |> List.wrap()
      |> Enum.flat_map(&Path.wildcard/1)

    :ok = DenoEx.lock_dependencies(scripts, lock_file_path, args)
    Mix.shell().info("Created #{lock_file_path}")
  end
end
