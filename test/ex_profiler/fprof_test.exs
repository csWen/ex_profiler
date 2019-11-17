defmodule ExProfiler.FprofTest do
  use ExUnit.Case, async: false

  use Mimic

  @trace_file "/tmp/fprof.trace"

  alias ExProfiler.Fprof

  setup :set_mimic_global

  setup do
    stub(:fprof, :trace, fn _ -> :ok end)

    stub(:fprof, :profile, fn _ -> :ok end)
    stub(:fprof, :analyse, fn _ -> :ok end)

    Fprof.start_link([])

    on_exit(fn -> GenServer.stop(Fprof) end)

    :ok
  end

  describe "profiling works" do
    test "profiling works for alive pids" do
      pid1 = spawn_process(:alive)
      pid2 = spawn_process(:alive)

      assert :ok == Fprof.start_profile([pid1, pid2], file: @trace_file, sort: :own)
      assert %Fprof{sort: :own, state: :profiling} = :sys.get_state(Fprof)

      new_pid = spawn_process(:alive)
      assert {:error, "busying"} == Fprof.start_profile([new_pid], file: @trace_file, sort: :own)
      assert %Fprof{sort: :own, state: :profiling} = :sys.get_state(Fprof)

      stop([pid1])
      assert %Fprof{state: :profiling} = :sys.get_state(Fprof)
      stop([pid2])
      assert %Fprof{state: :profiling} = :sys.get_state(Fprof)

      Process.sleep(1000)
      assert %Fprof{state: :waiting} = :sys.get_state(Fprof)

      stop([new_pid])
    end

    test "profiling works for atom spec" do
      assert {:error, "no supported pid and port specs"} ==
               Fprof.start_profile([:invalid1, :invalid2], file: @trace_file, sort: :own)

      assert :ok == Fprof.start_profile(:existing, file: @trace_file, sort: :own)
      assert %Fprof{sort: :own, state: :profiling} = :sys.get_state(Fprof)

      Fprof.stop_profile()
      Process.sleep(1000)
      assert %Fprof{sort: :acc, state: :waiting} = :sys.get_state(Fprof)
    end
  end

  test "appply works" do
    # assert :ok = Fprof.start_apply(IO, :puts, ["apply test"], file: @trace_file)
    # assert %Fprof{sort: :acc, state: :waiting} = :sys.get_state(Fprof)
  end

  defp spawn_process(:alive) do
    spawn(fn ->
      receive do
        _ -> :ok
      end
    end)
  end

  defp spawn_process(_) do
    spawn(fn -> :ok end)
  end

  defp stop(pids), do: Enum.each(pids, fn pid -> send(pid, :ok) end)
end
