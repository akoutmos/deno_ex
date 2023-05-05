<p align="center">
  <img align="center" width="25%" src="guides/images/logo.svg" alt="DenoEx Logo">
</p>

<p align="center">
  Easily run TypeScript and Javascript using <a href="https://deno.com/" target="_blank">Deno</a> right from Elixir!
</p>

<p align="center">
  <a href="https://hex.pm/packages/deno_ex">
    <img alt="Hex.pm" src="https://img.shields.io/hexpm/v/deno_ex?style=for-the-badge">
  </a>

  <a href="https://github.com/akoutmos/deno_ex/actions">
    <img alt="GitHub Workflow Status (master)"
    src="https://img.shields.io/github/actions/workflow/status/akoutmos/deno_ex/main.yml?label=Build%20Status&style=for-the-badge&branch=master">
  </a>

  <a href="https://coveralls.io/github/akoutmos/deno_ex?branch=master">
    <img alt="Coveralls master branch" src="https://img.shields.io/coveralls/github/akoutmos/deno_ex/master?style=for-the-badge">
  </a>

  <a href="https://github.com/sponsors/akoutmos">
    <img alt="Support the project" src="https://img.shields.io/badge/Support%20the%20project-%E2%9D%A4-lightblue?style=for-the-badge">
  </a>
</p>

<br>

# Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Supporting DenoEx](#supporting-denoex)
- [Using DenoEx](#using-denoex)

## Introduction

DenoEx is designed to make it simple to run scripts using [Deno](https://deno.com/runtime) from your Elixir
applications. Deno is a modern runtime for JavaScript and TypeScript that uses V8 and built-in Rust. It is secure by
default, so you must opt into each level of access your scripts need when running. This includes reading environment
variables.

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

### Installing the Runtime

By default Deno will automatically be installed in the package's `priv` directory
as part of the compilation process. If you would like the build to place Deno in
a different directory you may configure it. See the "Configuration" section of
`DenoEx`.

### Using DenoEx to Install Copies of the Runtime

Once you have DenoEx, you will need the Deno runtime. We have created a mix task
that you can use to install Deno. By default, Deno will be installed in the
`priv` directory for the `deno_ex` dependency. `my_project/_build/dev/lib/deno_ex/priv/bin`

  `mix deno_ex.install`

The installation path may be changed using `--path <path>`. Permissions may also
be changed on the `deno` executable using `--chmod <octal>`. The default
permissions are `0x770`.

## Supporting DenoEx

If you rely on this library to run TypeScript and Javascript within your application, it would much appreciated
if you can give back to the project in order to help ensure its continued development.

Checkout my [GitHub Sponsorship page](https://github.com/sponsors/akoutmos) if you want to help out!

### Gold Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58083">
  <img align="center" height="175" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Silver Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58082">
  <img align="center" height="150" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Bronze Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=17615">
  <img align="center" height="125" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

## Using DenoEx

Create a Typescript file with the following contents.

```typescript
console.log("Hello, world.")
```

Open iex using `iex -S mix` and then run the TypeScript file:

```elixir
iex > DenoEx.run({:file, "path/to/file.ts"})
```
