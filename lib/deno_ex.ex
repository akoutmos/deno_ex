defmodule DenoEx do
  @moduledoc """
  DenoEx is used to run javascript and typescript
  files in a safe environment.
  """

  @type script() :: String.t()
  @type script_arguments() :: [String.t()]
  @type options() :: keyword()

  @default_executable_path Application.compile_env(
                             :deno_ex,
                             :default_exectutable_path,
                             :deno_ex |> :code.priv_dir() |> Path.join("bin")
                           )

  @run_options_schema [
                        deno_path: [
                          type: :string,
                          doc: "the path where the deno executable is installed."
                        ],
                        allow_env: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          This option allows read and write access to environment variables.

                          true: allows full access to the environment variables
                          [String.t()]: allows access to only the subset of variables in the list.
                          """
                        ],
                        allow_sys: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          This option allows axxess to APIs that provide system information.
                          ie. hostname, memory usage

                          true: allows full access
                          [String.t()]: allows access to only the subset calls.
                          hostname, osRelease, osUptime, loadavg, networkInterfaces,
                          systemMemoryInfo, uid, and gid
                          """
                        ],
                        allow_hrtime: [
                          type: :boolean,
                          doc: """
                          Allow high-resolution time measurement. High-resolution time can be used in timing attacks and fingerprinting.
                          """
                        ]
                      ]
                      |> NimbleOptions.new!()
  @doc """
  Uses `deno run` to run a Deno script.

  ## Options

    #{NimbleOptions.docs(@run_options_schema)}

    Please refere to [Deno Permissions](https://deno.com/manual@v1.33.1/basics/permissions) for more details.

  """
  @spec run(script, script_arguments, options) :: {:ok, String.t()} | {:error, term()}
  def run(script, script_args \\ [], options \\ []) do
    with {:ok, options} <- NimbleOptions.validate(options, @run_options_schema),
         {exec_path, deno_options} = Keyword.pop(options, :deno_path, executable_path()) do
      deno_options = Enum.map(deno_options, &to_command_line_option/1)

      deno_path =
        [
          "#{exec_path}/deno run",
          deno_options,
          script,
          script_args
        ]
        |> List.flatten()
        |> Enum.join(" ")

      {:ok, _pid, identifier} =
        deno_path
        |> :exec.run_link([:stdout, :stderr])

      receive do
        {:stdout, ^identifier, output} ->
          :exec.stop(identifier)
          {:ok, output}

        {:stderr, ^identifier, output} ->
          :exec.stop(identifier)
          {:error, output}
      end
    end
  end

  def executable_path do
    System.get_env("DENO_PATH", @default_executable_path)
  end

  defp to_command_line_option({option, true}) do
    string_option =
      option
      |> to_string()
      |> String.replace("_", "-")

    "--#{string_option}"
  end

  defp to_command_line_option({_option, false}) do
    ""
  end

  defp to_command_line_option({option, values}) when is_list(values) do
    string_option =
      option
      |> to_string()
      |> String.replace("_", "-")

    string_values = Enum.join(values, ",")
    "--#{string_option}=#{string_values}"
  end
end
