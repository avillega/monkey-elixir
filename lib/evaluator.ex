defmodule Evaluator do
  alias AST.ReturnStmt
  def eval(nil), do: nil

  def eval(node) do
    case node.type do
      :program -> eval_stmts(node.statements)
      :block_stmt -> eval_stmts(node.statements)
      :expression_stmt -> eval(node.expression)
      :int_literal -> node.value
      :bool_literal -> node.value
      :prefix_expression -> eval_prefix_expr(node)
      :infix_expression -> eval_infix_expr(node)
      :if_expression -> eval_if_expression(node)
      :function_literal -> raise "unimplemented"
      :call_expression -> raise "unimplemented"
      _ -> nil
    end
  end

  defp eval_stmts([%ReturnStmt{ret_value: ret_val} | _]),
    do: eval(ret_val)

  defp eval_stmts([stmt]), do: eval(stmt)

  defp eval_stmts([stmt | rest]) do
    eval(stmt)
    eval_stmts(rest)
  end

  defp eval_prefix_expr(node) do
    right = eval(node.right)

    case node.operator do
      "!" -> !right
      "-" when is_integer(right) -> -right
      _ -> nil
    end
  end

  defp eval_infix_expr(node) do
    left = eval(node.left)
    right = eval(node.right)
    do_eval_infix_expr(node.operator, left, right)
  end

  defp do_eval_infix_expr(operator, left, right) when is_number(left) and is_number(right) do
    case operator do
      "+" -> left + right
      "-" -> left - right
      "*" -> left * right
      "/" -> div(left, right)
      "<" -> left < right
      ">" -> left > right
      "==" -> left == right
      "!=" -> left != right
      _ -> nil
    end
  end

  defp do_eval_infix_expr(operator, left, right) do
    case operator do
      "==" -> left == right
      "!=" -> left != right
      _ -> nil
    end
  end

  defp eval_if_expression(node) do
    condition = eval(node.condition)

    if is_truthy(condition) do
      eval(node.then)
    else
      eval(node.else)
    end
  end

  defp is_truthy(val) do
    case val do
      nil -> false
      false -> false
      _ -> true
    end
  end
end
