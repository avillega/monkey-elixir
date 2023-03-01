defmodule Evaluator do
  def eval(node) do
    do_eval(node)
  end

  defp do_eval(nil), do: {:ok, nil}

  defp do_eval(node) do
    case node.type do
      :program -> eval_program(node.statements)
      :block_stmt -> eval_block(node.statements)
      :expression_stmt -> do_eval(node.expression)
      :return_stmt -> eval_return_stmt(node)
      :int_literal -> {:ok, node.value}
      :bool_literal -> {:ok, node.value}
      :prefix_expression -> eval_prefix_expr(node)
      :infix_expression -> eval_infix_expr(node)
      :if_expression -> eval_if_expression(node)
      :function_literal -> raise "unimplemented"
      :call_expression -> raise "unimplemented"
      _ -> nil
    end
  end

  defp eval_program([stmt | rest]) do
    with {:ok, val} <- do_eval(stmt) do
      if rest != [] do
        eval_program(rest)
      else
        {:ok, val}
      end
    else
      {:ret, val} -> {:ok, val}
      err -> err
    end
  end

  defp eval_block([stmt | rest]) do
    with {:ok, val} <- do_eval(stmt) do
      if rest != [], do: eval_block(rest), else: {:ok, val}
    end
  end

  defp eval_return_stmt(stmt) do
    with {:ok, val} <- do_eval(stmt.ret_value), do: {:ret, val}
  end

  defp eval_prefix_expr(node) do
    with {:ok, right} <- do_eval(node.right) do
      case node.operator do
        "!" -> {:ok, !right}
        "-" when is_integer(right) -> {:ok, -right}
        _ -> {:error, "unknown operator: #{node.operator} for #{right}"}
      end
    end
  end

  defp eval_infix_expr(node) do
    with {:ok, left} <- do_eval(node.left),
         {:ok, right} <- do_eval(node.right) do
      do_eval_infix_expr(node.operator, left, right)
    end
  end

  defp do_eval_infix_expr(operator, left, right) when is_number(left) and is_number(right) do
    case operator do
      "+" -> {:ok, left + right}
      "-" -> {:ok, left - right}
      "*" -> {:ok, left * right}
      "/" -> {:ok, div(left, right)}
      "<" -> {:ok, left < right}
      ">" -> {:ok, left > right}
      "==" -> {:ok, left == right}
      "!=" -> {:ok, left != right}
      _ -> {:error, "unknown operator: #{operator} for left: #{left} and right: #{right}"}
    end
  end

  defp do_eval_infix_expr(operator, left, right) do
    case operator do
      "==" -> {:ok, left == right}
      "!=" -> {:ok, left != right}
      _ -> {:error, "unknown operator: #{operator} for left: #{left} and right: #{right}"}
    end
  end

  defp eval_if_expression(node) do
    with {:ok, condition} <- do_eval(node.condition) do
      if is_truthy(condition) do
        do_eval(node.then)
      else
        do_eval(node.else)
      end
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
