defmodule ExProfiler.UtilsTest do
  use ExUnit.Case

  require ExProfiler.Utils
  alias ExProfiler.Utils

  test "should get correct analysis file name" do
    assert "/a/b/c.analysis" == Utils.get_analysis_file("/a/b/c.test")
    assert "/a/b/c.analysis" == Utils.get_analysis_file("/a/b/c")
    assert "c.analysis" == Utils.get_analysis_file("c.test")
    assert "c.analysis" == Utils.get_analysis_file("c")
  end

  test "should get correct supported pid spec" do
    pid = spawn(fn -> :ok end)

    assert [true, false, true] ==
             Enum.map([:existing_ports, "invalid_spec", pid], fn
               spec when Utils.is_supported_spec(spec) -> true
               _ -> false
             end)
  end
end
