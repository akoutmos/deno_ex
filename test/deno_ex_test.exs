defmodule DenoExTest do
  use ExUnit.Case
  doctest DenoEx

  setup_all :create_test_file

  def create_test_file(env) do
    tmp_dir = System.tmp_dir!()
    filename = System.monotonic_time() |> to_string()

    path = Path.join(tmp_dir, filename)
    _ = File.rm(path)

    content = System.monotonic_time() |> to_string()

    File.write!(path, content)

    env
    |> Map.put(:path, path)
    |> Map.put(:content, content)
  end

  test "works with no arguments" do
    assert {:ok, "Hello, world.\n"} ==
             DenoEx.run(Path.join(~w[test support hello.ts]))
  end

  test "can pass script arguments" do
    assert {:ok, "arg1 arg2\n"} ==
             DenoEx.run(Path.join(~w[test support args_echo.ts]), ~w[arg1 arg2])
  end

  test "large outputs" do
    lines = 9
    per_line = 100

    expected_output =
      "a"
      |> String.duplicate(per_line)
      |> then(&(&1 <> "\n"))
      |> String.duplicate(lines)

    script = Path.join(~w[test support how_many_chars.ts])

    assert {:ok, expected_output} ==
             DenoEx.run(
               script,
               ~w[#{lines * per_line} #{per_line}]
             )
  end

  test "bad exit" do
    script = Path.join(~w[test support fail.ts])
    assert {:error, message} = DenoEx.run(script, ~w[])

    assert message =~ "exited with status code"
  end

  test "unknown deno arguments" do
    assert {:error,
            %NimbleOptions.ValidationError{
              message: message,
              key: [:unknown],
              value: nil,
              keys_path: []
            }} = DenoEx.run(Path.join(~w[test support args_echo.ts]), ~w[arg], unknown: "foo")

    assert message =~ "unknown options"
  end

  describe "allow_env option" do
    setup do
      {:ok, %{script: Path.join(~w[test support env_echo.ts])}}
    end

    test "can't access env variables when allow env not set", %{script: script} do
      assert {:error, error_message} = DenoEx.run(script, ~w[USER], [])

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, ~w[USER], allow_env: false)

      assert error_message =~ "PermissionDenied"
    end

    test "allows access to all env variables with true", %{script: script} do
      user = System.get_env("USER")

      assert {:ok, "USER #{user}\n"} ==
               DenoEx.run(script, ~w[USER], allow_env: true)
    end

    test "allows access to only listed env variables", %{script: script} do
      user = System.get_env("USER")
      shell = System.get_env("SHELL")

      assert {:ok, "USER #{user}\n"} ==
               DenoEx.run(script, ~w[USER], allow_env: ~w[SHELL USER])

      assert {:ok, "SHELL #{shell}\n"} ==
               DenoEx.run(script, ~w[SHELL], allow_env: ~w[SHELL USER])

      assert {:error, error_message} = DenoEx.run(script, ~w[USER], allow_env: ~w[SHELL])

      assert error_message =~ "PermissionDenied"
    end
  end

  describe "allow_sys option" do
    setup do
      {:ok, %{script: Path.join(~w[test support system_calls.ts])}}
    end

    test "can't access system information without the flag", %{script: script} do
      assert {:error, error_message} = DenoEx.run(script, ~w[], [])

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, ~w[], allow_sys: false)

      assert error_message =~ "PermissionDenied"
    end

    test "full access", %{script: script} do
      {:ok, hostname} = :inet.gethostname()

      assert {:ok, "#{hostname}\n"} ==
               DenoEx.run(script, ~w[], allow_sys: true)
    end

    test "partial access", %{script: script} do
      {:ok, hostname} = :inet.gethostname()

      assert {:ok, "#{hostname}\n"} ==
               DenoEx.run(script, ~w[], allow_sys: ~w[hostname uid])

      assert {:error, error_message} = DenoEx.run(script, ~w[], allow_sys: ~w[uid])

      assert error_message =~ "PermissionDenied"
    end
  end

  describe "allow_net" do
    setup do
      {:ok, %{script: Path.join(~w[test support network.ts])}}
    end

    test "not allowed", %{script: script} do
      assert {:error, error_message} = DenoEx.run(script, ~w[0.0.0.0 9999])

      assert error_message =~ "PermissionDenied"
    end

    test "allowing across the board", %{script: script} do
      assert {:ok, _} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: true)
    end

    test "allowing access to specific addresses", %{script: script} do
      assert {:ok, _} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[0.0.0.0])

      assert {:error, error_message} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[0.0.0.1])

      assert error_message =~ "PermissionDenied"
    end

    test "allowing access to specific ports", %{script: script} do
      assert {:ok, _} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[:9999])

      assert {:error, error_message} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[:9998])

      assert error_message =~ "PermissionDenied"
    end

    test "allowing access to specific address and port", %{script: script} do
      assert {:ok, _} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[0.0.0.0:9999])

      assert {:error, error_message} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[0.0.0.0:9998])

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, ~w[0.0.0.0 9999], allow_net: ~w[0.0.0.1:9999])

      assert error_message =~ "PermissionDenied"
    end
  end

  describe "allow_hrtime" do
    setup do
      {:ok, %{script: Path.join(~w[test support hrtime.ts])}}
    end

    test "without hrtime allowed", %{script: script} do
      non_high_resolution = 1_000_000

      assert {:ok, time} = DenoEx.run(script, ~w[], allow_hrtime: false)

      {time, _} = Integer.parse(time)

      assert rem(time, non_high_resolution) == 0

      assert {:ok, time} = DenoEx.run(script, ~w[])
      {time, _} = Integer.parse(time)

      assert rem(time, non_high_resolution) == 0
    end

    test "when hrtime is allowed", %{script: script} do
      non_high_resolution = 1_000_000

      # using two times to reduce the chance that both will be ending in 000_000
      assert {:ok, time} = DenoEx.run(script, ~w[], allow_hrtime: true)

      assert {:ok, time2} = DenoEx.run(script, ~w[], allow_hrtime: true)

      {time, _} = Integer.parse(time)
      {time2, _} = Integer.parse(time2)

      assert rem(time + time2, non_high_resolution) != 0
    end
  end

  test "allow_ffi" do
    script = Path.join(~w[test support hello.ts])

    assert {:ok, "Hello, world.\n"} ==
             DenoEx.run(script, ~w[], allow_ffi: true)

    assert {:ok, "Hello, world.\n"} ==
             DenoEx.run(script, ~w[], allow_ffi: [Path.join(~w[path to lib])])
  end

  describe "allow_run" do
    setup do
      {:ok, %{script: Path.join(~w[test support subprocess.ts])}}
    end

    test "errors when not allowed", %{script: script} do
      assert {:error, error_message} = DenoEx.run(script, ~w[], [])

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, ~w[], allow_run: false)

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, ~w[], allow_run: ~w[ls])

      assert error_message =~ "PermissionDenied"
    end

    test "when allowed", %{script: script} do
      assert {:ok, "hello\n"} ==
               DenoEx.run(script, ~w[], allow_run: true)

      assert {:ok, "hello\n"} ==
               DenoEx.run(script, ~w[], allow_run: ~w[echo])
    end
  end

  describe "allow_write" do
    setup do
      {:ok, %{script: Path.join(~w[test support write_file.ts])}}
    end

    test "errors when not allowed", %{script: script} do
      test_file = Path.join(System.tmp_dir(), "test_file")

      assert {:error, error_message} = DenoEx.run(script, ~w[#{test_file} hello])

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, ~w[#{test_file} hello], allow_write: false)

      assert error_message =~ "PermissionDenied"

      other_file = Path.join(System.tmp_dir(), "other_file")

      assert {:error, error_message} = DenoEx.run(script, ~w[#{test_file} hello], allow_write: [other_file])

      assert error_message =~ "PermissionDenied"
    end

    test "when allowed", %{script: script} do
      file = Path.join(System.tmp_dir(), "test_file")

      assert {:ok, "File written #{file} with hello\n"} ==
               DenoEx.run(script, ~w[#{file} hello], allow_write: true)

      assert {:ok, "File written #{file} with hello\n"} ==
               DenoEx.run(script, ~w[#{file} hello], allow_write: [file])
    end
  end

  describe "allow_read" do
    setup do
      {:ok, %{script: Path.join(~w[test support read_file.ts])}}
    end

    test "errors when not allowed", %{path: path, script: script} do
      assert {:error, error_message} = DenoEx.run(script, [path])

      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} = DenoEx.run(script, [path], allow_read: false)

      assert error_message =~ "PermissionDenied"

      file = Path.join(System.tmp_dir(), "other_file")

      assert {:error, error_message} = DenoEx.run(script, [path], allow_read: [file])

      assert error_message =~ "PermissionDenied"
    end

    test "when allowed to read", %{path: path, content: content, script: script} do
      assert {:ok, "#{content}\n"} ==
               DenoEx.run(script, [path], allow_read: true)

      assert {:ok, "#{content}\n"} ==
               DenoEx.run(script, [path], allow_read: [path])
    end
  end

  describe "allow_all" do
    @values [
      {"env_echo", ~w[USER]},
      {"how_many_chars", ~w[10 9]},
      {"hrtime", []},
      {"network", ~w[0.0.0.0 8888]}
    ]

    for {script, args} <- @values do
      @tag args: args, script: script
      test "#{script}", %{args: args, script: script} do
        assert {:ok, _} = DenoEx.run(Path.join(["test", "support", "#{script}.ts"]), args, allow_all: true)
      end
    end

    test "read", %{path: path, content: content} do
      assert {:ok, "#{content}\n"} ==
               DenoEx.run(Path.join(~w[test support read_file.ts]), [path], allow_all: true)
    end

    test "write" do
      file = Path.join(System.tmp_dir(), "test_file")

      assert {:ok, "File written #{file} with hello\n"} ==
               DenoEx.run(Path.join(~w[test support write_file.ts]), ~w[#{file} hello], allow_all: true)
    end
  end
end
