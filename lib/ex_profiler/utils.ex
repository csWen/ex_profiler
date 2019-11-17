defmodule ExProfiler.Utils do
  @moduledoc """
  Some utils used by profiler
  """

  @doc """
  Get analysis file name by trace file name
  ## Examples

    iex> get_analysis_file("/home/ubuntu/fprof.trace")
    "/home/ubuntu/fprof.analysis"

    iex> get_analysis_file("./fprof")
    "./fprof.analysis"
  """
  @spec get_analysis_file(String.t()) :: String.t()
  def get_analysis_file(trace_file) do
    case Path.extname(trace_file) do
      "" ->
        trace_file <> ".analysis"

      ext ->
        Path.rootname(trace_file, ext) <> ".analysis"
    end
  end

  defmacro is_supported_spec(spec) do
    quote do
      is_pid(unquote(spec)) or is_port(unquote(spec)) or
        unquote(spec) in [
          :all,
          :processes,
          :ports,
          :existing,
          :existing_processes,
          :existing_ports,
          :new,
          :new_processes,
          :new_ports
        ]
    end
  end
end
