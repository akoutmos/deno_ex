defmodule DenoExTest do
  use ExUnit.Case
  doctest DenoEx

  setup_all :ensure_deno_installed

  def ensure_deno_installed(env) do
    deno_path = "#{DenoEx.executable_path()}/deno"
    File.rm(deno_path)

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
end
