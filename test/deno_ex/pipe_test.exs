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
            }} = Pipe.new(@script, ~w[arg], unknown: "foo")

    assert message =~ "unknown options"
  end

  test "initializing a pipe" do
    assert %{command: command, status: :initialized} = Pipe.new(@script, ~w[arg], allow_env: ~w[USER SHELL])

    assert command =~ DenoEx.executable_location()
    assert command =~ @script
    assert command =~ "arg"
    assert command =~ "--allow-env=USER,SHELL"
  end

  test "initializing with a different deno location" do
    assert %{command: command} = Pipe.new(@script, ~w[arg], deno_location: "path")
    refute command =~ DenoEx.executable_location()
    assert command =~ "path/deno"
  end

  test "run with a good script" do
    assert %{status: :running} =
             @script
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
  end

  test "running when already running" do
    assert_raise FunctionClauseError, fn ->
      @script
      |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.run()
    end
  end

  test "awaiting a running script" do
    assert %{status: {:exit, :normal}} =
             @script
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()
  end

  test "timeout while awaiting" do
    assert %{status: {:exit, :timeout}} =
             @script
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await(1)
  end

  test "non-zero exit" do
    assert %{status: {:exit, exit_code}} =
             Path.join(~w[test support fail.ts])
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()

    assert is_integer(exit_code)
  end

  test "getting stdout from a pipe" do
    assert ["arg foo\n"] =
             @script
             |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()
             |> Pipe.output(:stdout)
  end

  test "getting stderr from pipe" do
    assert ["Bad Exit"] =
             Path.join(~w[test support fail.ts])
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.await()
             |> Pipe.output(:stderr)
  end

  test "finished" do
    assert @script
           |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.await()
           |> Pipe.finished?()

    refute @script
           |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.finished?()

    assert Path.join(~w[test support fail.ts])
           |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.await()
           |> Pipe.finished?()

    assert @script
           |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.await(1)
           |> Pipe.finished?()
  end
end
