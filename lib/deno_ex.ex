defmodule DenoEx do
  @default_executable_path :deno_ex |> :code.priv_dir() |> Path.join("bin")
  @env_location_variable "DENO_LOCATION"

  alias DenoEx.Pipe

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

       iex> DenoEx.run({:file, Path.join(~w[test support hello.ts])}, [], [deno_location: "#{@default_executable_path}"])
       {:ok, "Hello, world.#{"\\n"}"}

  ### Application Configuration

       import Config

       config :deno_ex,
         exectutable_location: Path.join(~w[path containing deno])

  ### ENV Variable

    `#{@env_location_variable}=path`
  """

  @executable_path Application.compile_env(
                     :deno_ex,
                     :exectutable_location,
                     @default_executable_path
                   )

  @typedoc """
  The path to the script that should be executed, or a tuple denoting
  what should be passed to the Deno executable over STDIN.
  """
  @type script() :: {:file, Path.t()} | {:stdin, IO.chardata()}

  @typedoc "The list of arguements to be passed to the script"
  @type script_arguments() :: [String.t()]

  @typedoc "The arguments for deno"
  @type options() :: Pipe.options()

  @doc """
  Uses `deno run` to run a Deno script.

  ## Options

    #{NimbleOptions.docs(Pipe.run_options_schema())}

    Please refer to [Deno Permissions](https://deno.com/manual@v1.33.1/basics/permissions) for more details.

  ## Examples

       iex> DenoEx.run({:file, Path.join(~w[test support hello.ts])})
       {:ok, "Hello, world.#{"\\n"}"}

       iex> DenoEx.run({:file, Path.join(~w[test support args_echo.ts])}, ~w[foo bar])
       {:ok, "foo bar#{"\\n"}"}

       iex> DenoEx.run({:stdin, "console.log(\\"Hello, world.\\")"})
       {:ok, "Hello, world.#{"\\n"}"}
  """
  @spec run(script(), script_arguments(), options(), timeout()) :: {:ok | :error, String.t()}
  def run(script, script_arguments \\ [], options \\ [], timeout \\ :timer.seconds(5)) do
    script
    |> Pipe.new(script_arguments, options)
    |> Pipe.run()
    |> Pipe.yield(timeout)
    |> then(fn
      {:ok, pipe} ->
        {:ok, pipe |> Pipe.output() |> Enum.join("")}

      {:error, pipe} ->
        {:error, pipe |> Pipe.output() |> Enum.join("")}

      {:timeout, pipe} ->
        {:timeout, pipe |> Pipe.output() |> Enum.join("")}
    end)
  end

  @doc """
  Vendors Deno dependencies into the given location
  """
  def vendor_dependencies(script_paths, vendor_location, lock_file_location, args) do
    deno_path = Path.join(DenoEx.executable_path(), "deno")

    System.cmd(
      deno_path,
      ~w[vendor #{Enum.join(script_paths, " ")} --output #{vendor_location} --lock=#{lock_file_location}] ++ args
    )
  end

  @doc """
  Locks the Deno dependencies
  """
  def lock_dependencies(script_paths, lock_file_location, _args) do
    deno_path = Path.join(DenoEx.executable_path(), "deno")

    Enum.each(script_paths, fn script_path ->
      System.cmd(deno_path, ~w[cache --lock=#{lock_file_location} #{script_path}])
    end)
  end

  @doc """
  Returns the location where the deno script is expected to be located.
  """
  @spec executable_path() :: String.t()
  def executable_path do
    System.get_env(@env_location_variable, @executable_path)
  end

  @doc """
  Returns the vendor location where deno script dependencies will be stored
  """
  @spec vendor_dir(atom()) :: String.t()
  def vendor_dir(app) do
    Path.join([:code.priv_dir(app), "deno"])
  end

  @doc """
  Returns the default import map path
  """
  @spec import_map_path(atom()) :: String.t()
  def import_map_path(app) do
    Path.join(vendor_dir(app), "import_map.json")
  end

  @doc """
  Returns the default lock file path
  """
  @spec lock_file_path(atom()) :: String.t()
  def lock_file_path(app) do
    Path.join([vendor_dir(app), "deno.lock"])
  end
end
