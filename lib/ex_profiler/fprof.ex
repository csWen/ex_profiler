defmodule ExProfiler.Fprof do
  use GenServer

  require Logger

  require ExProfiler.Utils
  alias ExProfiler.Utils

  defstruct state: :waiting,
            refs: nil,
            file: "",
            sort: :acc

  # API functions 

  @doc """
  Starts a GenServer process to manage fprof.
  """
  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Start tracing the given `pid_port_spec`.
  The `pid_port_spec` is used to call erlang:trace(PidSpec, true, [{tracer, Tracer} | Flags]), it is either a process identifier (pid) for a local process, a port identifier, or one of the following atoms:
  - :all - All currently existing processes and ports and all that will be created in the future.
  - :processes - All currently existing processes and all that will be created in the future.
  - :ports - All currently existing ports and all that will be created in the future.
  - :existing - All currently existing processes and ports.
  - :existing_processes - All currently existing processes.
  - :existing_ports - All currently existing ports.
  - :new - All processes and ports that will be created in the future.
  - :new_processes - All processes that will be created in the future.
  - :new_ports - All ports that will be created in the future.

  The allowed `opts`:
  - {:file, file} - Specifies the filename of the trace. If the option file is given, or none of these options are given, the file "./fprof.trace" is used.
  - {:sort, sort} - Specifies if the analysis should be sorted according to the ACC column, which is the default, or the OWN column. The value of `sort` can be :acc and :own.
  """
  @spec start_profile(pid() | List.t(), Keyword.t()) :: term()
  def start_profile(pid, opts \\ [])

  def start_profile(pid_port_specs, opts) when is_list(pid_port_specs) do
    {file, sort} = get_opts(opts)
    # Make sure there is the output file
    ensure_file(file)

    pid_port_specs
    |> Enum.map(fn
      spec when Utils.is_supported_spec(spec) -> spec
      reg_name when is_atom(reg_name) -> Process.whereis(reg_name)
      _ -> nil
    end)
    |> Enum.filter(& &1)
    |> case do
      [] ->
        {:error, "no supported pid and port specs"}

      [spec] when is_atom(spec) ->
        GenServer.call(__MODULE__, {:start_profile_atom, spec, file, sort})

      pids ->
        GenServer.call(__MODULE__, {:start_profile_pids, pids, file, sort})
    end
  end

  def start_profile(spec, opts), do: start_profile([spec], opts)

  @doc """
  Calls :fprof.apply/4
  """
  @spec start_apply(atom(), atom(), [term()], List.t()) :: term()
  def start_apply(m, f, a, opts) do
    {file, sort} = get_opts(opts)
    GenServer.call(__MODULE__, {:start_profile_apply, {m, f, a}, file, sort})
  end

  @doc """
  Stops a running fprof trace and clears all tracing from the node.
  """
  @spec stop_profile() :: :stop_profile
  def stop_profile(), do: send(__MODULE__, :stop_profile)

  # Internal functions

  @impl true
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(
        {:start_profile_pids, pids, file, sort},
        _from,
        %__MODULE__{state: :waiting} = state
      ) do
    refs = pids |> Enum.map(&Process.monitor/1) |> MapSet.new()
    new_state = %__MODULE__{state | state: :profiling, refs: refs, file: file, sort: sort}

    do_start_profile(pids, file, state, new_state)
  end

  @impl true
  def handle_call(
        {:start_profile_atom, spec, file, sort},
        _from,
        %__MODULE__{state: :waiting} = state
      ) do
    new_state = %__MODULE__{state | state: :profiling, file: file, sort: sort}

    do_start_profile(spec, file, state, new_state)
  end

  @impl true
  def handle_call(
        {:start_profile_apply, {m, f, a}, file, sort},
        _from,
        %__MODULE__{state: :waiting}
      ) do
    :fprof.apply(m, f, a, [{:file, to_charlist(file)}])
    do_analysis(file, sort)
    {:reply, :ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(_, _from, state), do: {:reply, {:error, "busying"}, state}

  @impl true
  def handle_info(
        {:DOWN, ref, :process, _object, _reason},
        %__MODULE__{state: :profiling, refs: refs} = state
      )
      when not is_nil(refs) do
    refs = MapSet.delete(refs, ref)

    MapSet.size(refs) == 0 and send(self(), :stop_profile)

    {:noreply, %__MODULE__{state | refs: refs}}
  end

  @impl true
  def handle_info(:stop_profile, %__MODULE__{file: file, sort: sort}) do
    :fprof.trace([:stop])
    do_analysis(file, sort)

    {:noreply, %__MODULE__{}}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  @doc false
  defp do_start_profile(pid_spec, file, state, new_state) do
    case :fprof.trace([:start, {:procs, pid_spec}, {:file, to_charlist(file)}]) do
      :ok ->
        {:reply, :ok, new_state}

      {:error, reason} ->
        reason |> inspect |> Logger.error()
        {:reply, {:error, reason}, state}

      {:EXIT, server_pid, reason} ->
        Logger.error("Exit with reason: #{inspect(reason)}")
        {:reply, {:error, {server_pid, reason}}, state}
    end
  end

  @doc false
  defp do_analysis(file, sort) do
    analysis_file = Utils.get_analysis_file(file)
    ensure_file(analysis_file)

    :fprof.profile({:file, to_charlist(file)})
    :fprof.analyse([{:dest, to_charlist(analysis_file)}, {:sort, sort}])
  end

  @doc false
  defp ensure_file(file) do
    # TODO: ensure directory
    File.exists?(file) or File.touch!(file)
  end

  @doc false
  defp get_opts(opts) do
    file = Keyword.get(opts, :file, "#{File.cwd!()}/priv/fprof.trace")
    sort = (Keyword.get(opts, :sort) == :own && :own) || :acc
    {file, sort}
  end
end
