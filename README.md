# ExProfiler

ExProfiler is an Elixir wrapper for Erlang prof modules.

## Notice  
Those module is used to profile a program to find out how the execution time is used. Production environment with caution, Don't even use it in a production environment.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_profiler` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_profiler, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_profiler](https://hexdocs.pm/ex_profiler).
