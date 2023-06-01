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

    assert command == [
             Path.join(DenoEx.executable_location(), "deno"),
             "run",
             ["--allow-env=USER,SHELL"],
             @script,
             ["arg"]
           ]
  end

  test "initializing with a different deno location" do
    path = "somepath"
    assert %{command: {:file, command}} = Pipe.new({:file, @script}, ~w[arg], deno_location: path)

    assert command == [Path.join(path, "deno"), "run", [], @script, ["arg"]]
  end

  test "run with a good script" do
    assert %{status: :running} =
             {:file, @script}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
  end

  test "support iodata scripts" do
    assert %{status: :running} =
             {:stdin, ["console.log(", "hello", ")"]}
             |> Pipe.new([])
             |> Pipe.run()
  end

  test "support chardata scripts" do
    assert %{status: :running} =
             {:stdin, ["console.log(", 'hello', ?)]}
             |> Pipe.new([])
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

  test "yielding a running script" do
    assert {:ok, %{status: {:exit, :normal}}} =
             {:file, @script}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.yield()
  end

  test "timeout while yielding" do
    assert {:timeout, %{status: :timeout}} =
             {:file, @script}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.yield(1)
  end

  test "non-zero exit" do
    assert {:error, %{status: {:exit, exit_code}}} =
             {:file, Path.join(~w[test support fail.ts])}
             |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
             |> Pipe.run()
             |> Pipe.yield()

    assert is_integer(exit_code)
  end

  test "getting stdout from a pipe" do
    {:ok, pipe} =
      {:file, @script}
      |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.yield()

    assert ["arg foo\n"] = Pipe.output(pipe)
  end

  test "getting stderr from pipe" do
    {:error, pipe} =
      {:file, Path.join(~w[test support fail.ts])}
      |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.yield()

    assert ["Bad Exit"] = Pipe.output(pipe)
  end

  test "finished" do
    {:ok, pipe} =
      {:file, @script}
      |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.yield()

    assert Pipe.finished?(pipe)

    refute {:file, @script}
           |> Pipe.new(~w[arg foo], allow_env: ~w[USER SHELL])
           |> Pipe.run()
           |> Pipe.finished?()

    {:error, pipe} =
      {:file, Path.join(~w[test support fail.ts])}
      |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.yield()

    assert Pipe.finished?(pipe)

    {:timeout, pipe} =
      {:file, @script}
      |> Pipe.new(~w[arg], allow_env: ~w[USER SHELL])
      |> Pipe.run()
      |> Pipe.yield(1)

    assert Pipe.finished?(pipe)
  end
end
