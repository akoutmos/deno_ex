# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2023-07-07

### Added

- Support for Deno lock files

## [0.3.0] - 2023-06-02

### Changed

- Switched over to using Elixir's built in `Port` module as opposed to `:erl_exec`

## [0.2.0] - 2023-05-09

### Fixed

- Release was not packaging artifacts properly

## [0.1.0] - 2023-05-06

### Added

- The ability to download the Deno binary from Github
- The ability to run Typescript and Javascript scripts from STDIN
- The ability to execute Typescript and Javascript file from the file system
- Support for all of the Deno permission flags in order to sandbox running scripts
- Livebook example documents
