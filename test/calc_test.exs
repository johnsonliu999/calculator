defmodule CalcTest do
  use ExUnit.Case
  doctest Calc

  test "greets the world" do
    assert Calc.hello() == :world
  end

  test "2 + 3" do
    assert Calc.eval("2 + 3") == Code.eval_string("2 + 3") |> (elem 0)
  end

  test "5 * 1" do
    assert Calc.eval("5 * 1") == Code.eval_string("5 * 1") |> (elem 0)
  end

  test "24 / 6 + (5 -  4)" do
    assert Calc.eval("24 / 6 + (5 -  4)") == Code.eval_string("24 / 6 + (5 -  4)") |> (elem 0)
  end

  test "1 + 3 * 3 + 1" do
    assert Calc.eval("1 + 3 * 3 + 1") == Code.eval_string("1 + 3 * 3 + 1") |> (elem 0)
  end

  test "5 / 3 + 6 / 7" do
    assert Calc.eval("5 / 3 + 6 / 7") == 1
  end
end
