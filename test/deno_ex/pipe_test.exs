defmodule DenoEx.PipeTest do
  use ExUnit.Case, async: true
  alias DenoEx.Pipe
  doctest Pipe

  @script Path.join(~w[test support args_echo.ts])

  test "unknown deno arguments" do
    assert {:error,
            %NimbleOptions.ValidationError{
              message: message,
              key: [:unknown],
              value: nil,
              keys_path: []
            }} = Pipe.new({:file, @script}, ~w[arg], unknown: "foo")

    assert message =~ "unknown options"
  end

  test "initializing a pipe" do
    assert %{command: {:file, command}, status: :initialized} =
             Pipe.new({:file, @script}, ~w[arg], allow_env: ~w[USER SHELL])

    assert command =~ DenoEx.executable_location()
    assert command =~ @script
    assert command =~ "arg"
    assert command =~ "--allow-env=USER,SHELL"
  end

  test "initializing with a different deno location" do
    assert %{command: {:file, command}} = Pipe.new({:file, @script}, ~w[arg], deno_location: "path")
    refute command =~ DenoEx.executable_location()
    assert command =~ "path/deno"
  end

  test "run with a good script" do
    assert %{status: :running} =
             {:file, @script}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
  end

  test "running when already running" do
    assert_raise FunctionClauseError, fn ->
      {:file, @script}
      |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.run()
    end
  end

  test "awaiting a running script" do
    assert %{status: {:exit, :normal}} =
             {:file, @script}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()
  end

  test "timeout while awaiting" do
    assert %{status: {:exit, :timeout}} =
             {:file, @script}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await(1)
  end

  test "non-zero exit" do
    assert %{status: {:exit, exit_code}} =
             {:file, Path.join(~w[test support fail.ts])}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()

    assert is_integer(exit_code)
  end

  test "getting stdout from a pipe" do
    assert ["arg foo\n"] =
             {:file, @script}
             |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()
             |> Pipe.output(:stdout)
  end

  test "getting stderr from pipe" do
    assert ["Bad Exit"] =
             {:file, Path.join(~w[test support fail.ts])}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()
             |> Pipe.output(:stderr)
  end

  test "finished" do
    assert {:file, @script}
           |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.await()
           |> Pipe.finished?()

    refute {:file, @script}
           |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.finished?()

    assert {:file, Path.join(~w[test support fail.ts])}
           |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.await()
           |> Pipe.finished?()

    assert {:file, @script}
           |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.await(1)
           |> Pipe.finished?()
  end
end
