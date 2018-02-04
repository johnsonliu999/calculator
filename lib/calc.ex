defmodule Calc do
  @moduledoc """
  Documentation for Calc.
  """

  @doc """
  Hello world.

  ## Examples

  iex> Calc.hello
  :world

  """
  def hello do
    :world
  end

  def main do
    loop()
  end

  def loop do
    case IO.gets("> ") do
      :eof ->
        IO.puts "All done"
      {:error, reason} ->
        IO.puts "Error: #{reason}"
      line ->
        eval(line)
        |> IO.puts
        loop()
    end  
  end

  def eval(expr) do
    expr
    |> gen_postfix
    |> Enum.reverse
    |> eval_postfix
  end

  def gen_infix(expr) do
    expr
    |> String.replace(~r/\s+/, "")
    |> String.codepoints
    |> Enum.chunk_by(&(
      cond do
        &1 >= "0" && &1 <= "9" -> 0
        &1 === "-" -> 3
        is_operator(&1) -> 1
        &1 === "(" || &1 === ")" -> 2
      end
    ))
    |> combine
    |> add_par 
  end

  def is_operator(item) do
    item == "+" || item == "-" || item == "*" || item == "/"
  end

  def add_par(expr) do
    ["(" | expr] ++ [")"]
  end

  def combine(chunks) do
    chunks
    |> Enum.map(&(
      cond do
        hd(&1) >= "0" && hd(&1) <= "9" -> String.to_integer(Enum.join(&1))
        length(&1) == 1 -> hd(&1)
        length(&1) == 2 -> '^' 
      end
    ))
  end

  def eval_postfix(expr) do
    eval_postfix(expr, [])
  end

  def eval_postfix(expr, stack) do
#    stack |> IO.inspect(label: "[eval_postfix] stack")
    cond do
      length(expr) === 0 -> hd(stack)
      is_integer(hd(expr)) -> eval_postfix(tl(expr), [hd(expr) | stack])
      is_operator(hd(expr)) -> eval_postfix(tl(expr), eval_bin(hd(expr),stack))
    end
  end

  def eval_bin(op, [num2 | [num1 | tail]]) do
    case op do
      "+" -> [num1 + num2 | tail]
      "-" -> [num1 - num2 | tail]
      "*" -> [num1 * num2 | tail]
      "/" -> [div(num1, num2) | tail]
    end
  end

  def gen_postfix(expr) do
#    IO.puts gen_infix(expr)
    gen_postfix(gen_infix(expr), {[], []})
  end

  def gen_postfix(expr, {op_stack, out}) do
#    IO.puts("expr:" <> Enum.join(expr))
#    IO.puts("opstack:" <> (op_stack |> Enum.join))
#    IO.puts("out:" <> Enum.join(out) <> "\n")
    cond do
      length(op_stack) == 0 && length(expr) == 0  -> out
        hd(expr) === "(" 
        -> gen_postfix(tl(expr), {["(" | op_stack], out})
          is_integer(hd(expr)) 
          -> gen_postfix(tl(expr), {op_stack, [hd(expr) | out]})
            is_operator(hd(expr)) 
            -> gen_postfix(tl(expr), adjust_op_stack(hd(expr), {op_stack, out}))
      hd(expr) === ")" -> gen_postfix(tl(expr), pop_until_lp({op_stack, out}))
    end
  end

  def adjust_op_stack(op, {op_stack, out}) do
#    op |> IO.inspect(label: "op in adjust:")
#    op_stack |> IO.inspect(label: "op_stack in adjust:")
    cond do
      !is_operator(hd(op_stack)) -> {[op | op_stack], out}
      precede(op, hd(op_stack)) -> {[op | op_stack], out}
      true -> adjust_op_stack(op, {(tl op_stack), [hd(op_stack) | out]})
    end
  end

  def pop_until_lp({op_stack, out}) do
    case hd(op_stack) do
      "(" -> {tl(op_stack), out}
      o -> pop_until_lp({tl(op_stack), [o | out]})
    end
  end

  def precede(op1, op2, prior \\ %{"+"=> 0, "-"=> 0, "*"=> 1, "/"=> 1}) do
    prior[op1] > prior[op2]
  end

end
