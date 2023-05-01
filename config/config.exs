import Config

config :deno_ex,
  default_executable_path: "."

import_config "#{config_env()}.exs"
