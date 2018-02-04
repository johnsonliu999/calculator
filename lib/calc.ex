defmodule Calc do
  @moduledoc """
  A four function calculator with two API `eval` and `main`
  main: repeatedly print a prompt, read one line, eval it, and print 
        the result
  eval (string -> integer): parse and evaluate an arithmetic expression
  """

  @doc """
  Main entrance
  """
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

  @doc """
  Eval a string expression to a integer

  ### Examples
  
  iex> Calc.eval("1 + 3")
  4
  """ 
  def eval(expr) do
    expr
    |> gen_postfix
    |> Enum.reverse
    |> eval_postfix
  end

  # brief: genrate infix list of the expression
  # param expr[string]: the string arithmetic expression
  # return [list]: the infix list of the `expr`   
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

  # return true if `item` is valid operator
  def is_operator(item) do
    item == "+" || item == "-" || item == "*" || item == "/"
  end

  # brief: add parens to a list
  # param expr[list]: a list 
  # return [list]: `list` with parens both sides
  # example: add_par([1,2]) => ["(", 1, 2, ")"]
  defp add_par(expr) do
    ["(" | expr] ++ [")"]
  end

  # brief: combine chunks and combine single digits to a integer
  # param chunks[list of list]: a list of list
  # return [list]: list containing operators and operands
  # example: combine([["1", "2"], "+", "5"]) => [12, "+", 5]
  def combine(chunks) do
    chunks
    |> Enum.map(&(
      cond do
        hd(&1) >= "0" && hd(&1) <= "9" -> String.to_integer(Enum.join(&1))
        length(&1) == 1 -> hd(&1)
      end
    ))
  end

  # brief: eval postfix expression
  # param expr[list]: a list of operators and operands in postfix order
  # return [integer]: the answer to the expression
  # example: eval_postfix(["+", 5, 6]) => 11
  def eval_postfix(expr) do
    eval_postfix(expr, [])
  end

  # brief: helper function for `eval_postfix`
  # param expr[list]: a list of operators and operands
  # param stack: the stack to store operands
  # return [integer]: the answer to the expression
  defp eval_postfix(expr, stack) do
#    stack |> IO.inspect(label: "[eval_postfix] stack")
    cond do
      length(expr) === 0 -> hd(stack)
      is_integer(hd(expr)) -> eval_postfix(tl(expr), [hd(expr) | stack])
      is_operator(hd(expr)) -> eval_postfix(tl(expr), eval_bin(hd(expr),stack))
    end
  end

  # brief: do binary operation `op` and push back ans
  # param op[string]: the operator
  # param stack[list]: the stack of operands
  # return [list]: the new operand stack
  # example: eval_bin("+", [5, 6]) => [11]
  def eval_bin(op, [num2 | [num1 | tail]]) do
    case op do
      "+" -> [num1 + num2 | tail]
      "-" -> [num1 - num2 | tail]
      "*" -> [num1 * num2 | tail]
      "/" -> [div(num1, num2) | tail]
    end
  end

  # brief: generate postfix of the expression
  # param expr[string]: the expression
  # return [list]: a list of operators and operands in postfix order
  # example: gen_postfix("5 + 6") => ["+", 5, 6]
  def gen_postfix(expr) do
#    IO.puts gen_infix(expr)
    gen_postfix(gen_infix(expr), {[], []})
  end

  # brief: helper function of `gen_postfix`
  # param expr[string]: the expression
  # param stacks[tuple]: the operator stack and out stack
  # return [list]: a list of operators and operands in postfix order
  defp gen_postfix(expr, {op_stack, out}) do
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

  # brief: `op` is gonna be added to the op_stack and adjust the stack
  #        so that op has higher priority than the top operator of 
  #        the op_stack. Ops popped out is gonna to be added to `out`
  # param op[string]: the operator to be added to `op_stack`
  # param stacks[tuple]: the op_stack and out stack
  # return stacks[tuple]: the new stacks tuple after adjusting
  def adjust_op_stack(op, {op_stack, out}) do
#    op |> IO.inspect(label: "op in adjust:")
#    op_stack |> IO.inspect(label: "op_stack in adjust:")
    cond do
      !is_operator(hd(op_stack)) -> {[op | op_stack], out}
      precede(op, hd(op_stack)) -> {[op | op_stack], out}
      true -> adjust_op_stack(op, {(tl op_stack), [hd(op_stack) | out]})
    end
  end

  # brief: pop operators until the left paren is met
  # param stacks[tuple]: the op stack and out stack
  # return [tuple]: the new stacks tuple
  def pop_until_lp({op_stack, out}) do
    case hd(op_stack) do
      "(" -> {tl(op_stack), out}
      o -> pop_until_lp({tl(op_stack), [o | out]})
    end
  end

  # brief: if `op1` has higher priority than `op2`, return true
  #        otherwise false
  # param op1[string]: op1
  # param op2[string]: op2
  # param prior[map]: the priority map, the higher priority, the higher 
  #                   mapped value
  def precede(op1, op2, prior \\ %{"+"=> 0, "-"=> 0, "*"=> 1, "/"=> 1}) do
    prior[op1] > prior[op2]
  end

end
