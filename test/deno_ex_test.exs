defmodule DenoExTest do
  use ExUnit.Case
  doctest DenoEx

  setup_all :ensure_deno_installed

  def ensure_deno_installed(env) do
    deno_path = "#{DenoEx.executable_path()}/deno"
    unless File.exists?(deno_path) do
      DenoEx.DenoDownloader.install(DenoEx.executable_path(), 0o770)
    end

    {:ok, Map.put(env, :install_path, DenoEx.executable_path())}
  end

  test "works with no arguments" do
    assert {:ok, "Hello, world.\n"} ==
             DenoEx.run("test/support/hello.ts", _script_args = [])
  end

  test "can pass script arguments" do
    assert {:ok, "arg1 arg2\n"} ==
             DenoEx.run("test/support/args_echo.ts", ~w[arg1 arg2])
  end

  test "unknown deno arguments" do
    assert {:error,
            %NimbleOptions.ValidationError{
              message: "unknown options [:unknown], valid options are: [:deno_path, :allow_env]",
              key: [:unknown],
              value: nil,
              keys_path: []
            }} == DenoEx.run("test/support/args_echo.ts", ~w[arg], unknown: "foo")
  end

  describe "allow_env option" do
    test "can't access env variables when allow env not set" do
      assert {:error, error_message} = DenoEx.run("test/support/env_echo.ts", ~w[USER], [])
      assert error_message =~ "PermissionDenied"

      assert {:error, error_message} =
               DenoEx.run("test/support/env_echo.ts", ~w[USER], allow_env: false)

      assert error_message =~ "PermissionDenied"
    end

    test "allows access to all env variables with true" do
      user = System.get_env("USER")

      assert {:ok, "USER #{user}\n"} ==
               DenoEx.run("test/support/env_echo.ts", ~w[USER], allow_env: true)
    end

    test "allows access to only listed env variables" do
      user = System.get_env("USER")
      shell = System.get_env("SHELL")

      assert {:ok, "USER #{user}\n"} ==
               DenoEx.run("test/support/env_echo.ts", ~w[USER], allow_env: ~w[SHELL USER])

      assert {:ok, "SHELL #{shell}\n"} ==
               DenoEx.run("test/support/env_echo.ts", ~w[SHELL], allow_env: ~w[SHELL USER])

      assert {:error, error_message} =
               DenoEx.run("test/support/env_echo.ts", ~w[USER], allow_env: ~w[SHELL])

      assert error_message =~ "PermissionDenied"
    end
  end
end
