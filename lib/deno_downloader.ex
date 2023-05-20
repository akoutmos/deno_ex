defmodule DenoEx.DenoDownloader do
  @moduledoc """
  This module is responsible for fetching the deno executable from GitHub.
  """

  use OctoFetch,
    latest_version: "1.33.4",
    github_repo: "denoland/deno",
    download_versions: %{
      "1.33.4" => [
        {:darwin, :arm64, "ea504cac8ba53ef583d0f912d7834f4bff88eb647cfb10cb1dd24962b1dc062d"},
        {:darwin, :amd64, "1e2d79b4a237443e201578fc825052245d2a71c9a17e2a5d1327fa35f9e8fc0e"},
        {:linux, :amd64, "2e62448732a8481cae7af6637ddd37289e5baa6f22cd8e2f8197e25991869257"}
      ],
      "1.33.1" => [
        {:darwin, :arm64, "e4a531d061fa8151070a6323e35a23620d6889297b810b6424a5125842ecbb47"},
        {:darwin, :amd64, "20166aa1b24b89edfa7b7c34f1b940f52bf8300108178cd37a36e5dd8a899c36"},
        {:linux, :amd64, "dfe4f29aff4c885dd6196d7623f50c8aad9c1627be8bc9abe67e424aeb78f63e"}
      ]
    }

  defguard is_non_negative_integer(value) when is_integer(value) and value >= 0

  @impl true
  def download_name(_version, :darwin, :arm64), do: "deno-aarch64-apple-darwin.zip"
  def download_name(_version, :darwin, :amd64), do: "deno-x86_64-apple-darwin.zip"
  def download_name(_version, :darwin, arch), do: "deno-#{arch}-apple-darwin.zip"
  def download_name(_version, :linux, :amd64), do: "deno-x86_64-unknown-linux-gnu.zip"

  @doc """
  This function downloads the deno executable and also sets the permissions of the
  executable.
  """
  @spec install(install_path :: String.t(), permissions :: integer()) ::
          {:ok, path :: String.t()} | {:error, File.posix()}
  def install(install_path, permissions) when is_binary(install_path) and is_non_negative_integer(permissions) do
    with :ok <- File.mkdir_p(install_path),
         {:ok, [path], []} <-
           DenoEx.DenoDownloader.download(install_path) do
      :ok = File.chmod(path, permissions)
      {:ok, path}
    end
  end
end
