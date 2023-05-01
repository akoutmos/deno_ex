defmodule DenoEx do
  @moduledoc """
  DenoEx is used to run javascript and typescript
  files in a safe environment.
  """

  @type script() :: String.t()
  @type script_arguments() :: [String.t()]
  @type options() :: keyword()

  @default_executable_path Application.compile_env(:deno_ex, :default_exectutable_path, ".")

  @doc """
  Uses `deno run` to run a Deno script.
  """
  @spec run(script, script_arguments, options) :: {:ok, String.t()} | {:error, term()}
  def run(script, script_args \\ [], options \\ [deno_path: executable_path()]) do
    deno_path =
      "#{Keyword.get(options, :deno_path, executable_path())}/deno run " <>
        Enum.join([script | script_args], " ")

    {:ok, _pid, identifier} =
      deno_path
      |> :exec.run_link([:stdout])

    receive do
      {:stdout, ^identifier, output} ->
        {:ok, output}
    end
  end

  def executable_path do
    System.get_env("DENO_PATH", @default_executable_path)
  end
end
