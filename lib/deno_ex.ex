defmodule DenoEx do
  @default_executable_location :deno_ex |> :code.priv_dir() |> Path.join("bin")
  @env_location_variable "DENO_LOCATION"

  @moduledoc """
  DenoEx is used to run javascript and typescript files in a safe environment by utilizing
  [Deno](https://deno.com/runtime).

  ## Basics

  ## Configuration

  Configuration of the deno installation directory can be set in a few ways. We can use an
  environment variable, application config, or pass it directly to the run command. The
  different configurations are there to facilitate different working situations. The
  priorities are `function options` > `application configuration` > `environment`.

  ### Function Option

       iex> DenoEx.run(Path.join(~w[test support hello.ts]), [], [deno_location: "#{@default_executable_location}"])
       {:ok, "Hello, world.#{"\\n"}"}

  ## Application Configuration

       import Config

       config :deno_ex,
         exectutable_location: Path.join(~w[path containing deno])

  ## ENV Variable

    `#{@env_location_variable}=path`
  """

  @executable_location Application.compile_env(
                         :deno_ex,
                         :exectutable_location,
                         @default_executable_location
                       )

  @run_options_schema [
                        deno_location: [
                          type: :string,
                          doc: """
                          Sets the path where the deno executable is located.

                          Note: It does not include the deno executable. If the executable is located at
                          `/usr/bin/deno` then the `deno_location` should be `/usr/bin`.
                          """
                        ],
                        timeout: [
                          type: :pos_integer,
                          default: 5000,
                          doc: "Timeout in milliseconds to wait for the script to run before aborting."
                        ],
                        allow_env: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allows read and write access to environment variables.

                          `true`: allows full access to the environment variables

                          `[String.t()]`: allows access to only the subset of variables in the list.
                          """
                        ],
                        allow_sys: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allows access to APIs that provide system information.
                          i.e. hostname, memory usage

                          `true`: allows full access

                          `[String.t()]`: allows access to only the subset calls.
                          hostname, osRelease, osUptime, loadavg, networkInterfaces,
                          systemMemoryInfo, uid, and gid
                          """
                        ],
                        allow_net: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allows network access.

                          `true`: allows full access to the network

                          `[String.t()]`: allows access to only the network connections specified
                          ie. 127.0.0.1:4000, 127.0.0.1, :4001
                          """
                        ],
                        allow_hrtime: [
                          type: :boolean,
                          doc: """
                          Allows high-resolution time measurement. High-resolution time can be used in timing attacks and fingerprinting.
                          """
                        ],
                        allow_ffi: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allow loading of dynamic libraries.

                          ## WARNING:

                          Be aware that dynamic libraries are not run in a sandbox and therefore
                          do not have the same security restrictions as the Deno process.
                          Therefore, use it with caution.

                          `true`: allows all dlls to be accessed

                          `[Path.t()]`: A list of paths to dlls that will be accessible
                          """
                        ],
                        allow_run: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allow running subprocesses.

                          ## WARNING

                          Be aware that subprocesses are not run in a sandbox and therefore do not have
                          the same security restrictions as the Deno process. Therefore, use it with caution.

                          `true`: allows all subprocesses to be run

                          `[Path.t()]`: A list of subprocesses to run
                          """
                        ],
                        allow_write: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allow the ability to write files.

                          `true`: allows all files to be written

                          `[Path.t()]`: A list of files that can be written
                          """
                        ],
                        allow_read: [
                          type: {:or, [:boolean, list: :string]},
                          doc: """
                          Allow the ability to read files.

                          `true`: allows all files to be read

                          `[Path.t()]`: A list of files that can be read
                          """
                        ],
                        allow_all: [
                          type: :boolean,
                          doc: "Turns on all options and bypasses all security measures"
                        ]
                      ]
                      |> NimbleOptions.new!()

  @typedoc "The path to the script"
  @type script() :: Path.t()
  @typedoc "The list of arguements to be passed to the script"
  @type script_arguments() :: [String.t()]
  @typedoc "The arguments for deno"
  @type options() :: unquote(NimbleOptions.option_typespec(@run_options_schema))

  @doc """
  Uses `deno run` to run a Deno script.

  ## Options

    #{NimbleOptions.docs(@run_options_schema)}

    Please refer to [Deno Permissions](https://deno.com/manual@v1.33.1/basics/permissions) for more details.

  ## Examples

       iex> DenoEx.run(Path.join(~w[test support hello.ts]))
       {:ok, "Hello, world.#{"\\n"}"}

       iex> DenoEx.run(Path.join(~w[test support args_echo.ts]), ~w[foo bar])
       {:ok, "foo bar#{"\\n"}"}
  """
  @spec run(script, script_arguments, options) :: {:ok, String.t()} | {:error, term()}
  def run(script, script_args \\ [], options \\ []) do
    with {:ok, options} <- NimbleOptions.validate(options, @run_options_schema),
         {exec_location, deno_options} <-
           Keyword.pop(options, :deno_location, executable_location()),
         {timeout, deno_options} <- Keyword.pop(deno_options, :timeout) do
      deno_options = Enum.map(deno_options, &to_command_line_option/1)

      {:ok, pid, os_pid} =
        [
          Path.join(exec_location, "deno"),
          "run",
          deno_options,
          script,
          script_args
        ]
        |> List.flatten()
        |> Enum.join(" ")
        |> :exec.run([:stdout, :stderr, :monitor])

      # Initial state for reduce
      initial_reduce_results = %{
        stdout: "",
        stderr: []
      }

      result =
        [nil]
        |> Stream.cycle()
        |> Enum.reduce_while(initial_reduce_results, fn _, acc ->
          receive do
            {:DOWN, ^os_pid, _, ^pid, {:exit_status, exit_status}} when exit_status != 0 ->
              error = "Deno script exited with status code #{inspect(exit_status)}\n"
              existing_errors = Map.get(acc, :stderr, [])
              {:halt, Map.put(acc, :stderr, [error | existing_errors])}

            {:DOWN, ^os_pid, _, ^pid, :normal} ->
              {:halt, acc}

            {:stderr, ^os_pid, error} ->
              error = String.trim(error)
              existing_errors = Map.get(acc, :stderr, [])
              {:cont, Map.put(acc, :stderr, [error | existing_errors])}

            {:stdout, ^os_pid, compiled_template_fragment} ->
              aggregated_template = Map.get(acc, :stdout, "")
              {:cont, Map.put(acc, :stdout, aggregated_template <> compiled_template_fragment)}
          after
            timeout ->
              :exec.kill(os_pid, :sigterm)
              error = "Deno script timed out after #{timeout} millisecond(s)"
              existing_errors = Map.get(acc, :stderr, [])
              {:halt, Map.put(acc, :stderr, [error | existing_errors])}
          end
        end)

      case result do
        %{stderr: [], stdout: compiled_template} ->
          {:ok, compiled_template}

        %{stderr: errors} ->
          {:error, Enum.join(errors, "\n")}
      end
    end
  end

  @doc """
  Returns the location where the deno script is expected to be located.
  """
  @spec executable_location() :: binary()
  def executable_location do
    System.get_env(@env_location_variable, @executable_location)
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
