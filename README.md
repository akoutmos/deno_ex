# DenoEx

DenoEx is designed to make it simple to run scripts using
[Deno](https://deno.com/runtime) from your Elixir applications. Deno is a modern
runtime for JavaScript and TypeScript that uses V8 and built-in Rust. It is
secure by default, so you must opt into each level of access your
scripts need when running. This includes reading environment variables.

## Installation

The package can be installed by adding `deno_ex` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [
    {:deno_ex, "~> 0.1.0"}
  ]
end
```

## Installing the Runtime

By defualt Deno will automatically be installed in the package's `priv` directory
as part of the compilation process. If you would like the build to place deno in
a different directory you may configure it. See the "Configuration" section of
`DenoEx`.

## Using DenoEx to Install Copies of the Runtime

Once you have DenoEx, you will need the Deno runtime. We have created a mix task
that you can use to install Deno. By default, Deno will be installed in the
`priv` directory for the `deno_ex` dependency. `my_project/_build/dev/lib/deno_ex/priv/bin`

  `mix deno_ex.install`

The installation path may be changed using `--path <path>`. Permissions may also
be changed on the `deno` executable using `--chmod <octal>`. The default
permissions are `0x770`.

## Testing

Create a Typescript file with the following contents.

~~~typescript
console.log("Hello, world.")
~~~

Open iex using `iex -S mix`.

     iex> DenoEx.run("path/to/file.ts")
  
