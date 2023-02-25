defmodule Evaluator do
  def eval(node) do
    with {:ok, val} <- do_eval(node) do
      val
    end
  end

  defp do_eval(nil), do: {:ok, nil}

  defp do_eval(node) do
    case node.type do
      :program -> eval_program(node.statements)
      :block_stmt -> eval_block(node.statements)
      :expression_stmt -> do_eval(node.expression)
      :return_stmt -> {:ret, eval(node.ret_value)}
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
    end
  end

  defp eval_block([stmt | rest]) do
    with {:ok, val} <- dbg do_eval(stmt) do
      if rest != [], do: eval_block(rest), else: {:ok, val}
    end
  end

  defp eval_prefix_expr(node) do
    with {:ok, right} <- do_eval(node.right) do
      result =
        case node.operator do
          "!" -> !right
          "-" when is_integer(right) -> -right
          _ -> nil
        end

      {:ok, result}
    end
  end

  defp eval_infix_expr(node) do
    with {:ok, left} <- do_eval(node.left),
         {:ok, right} <- do_eval(node.right) do
      do_eval_infix_expr(node.operator, left, right)
    end
  end

  defp do_eval_infix_expr(operator, left, right) when is_number(left) and is_number(right) do
    result =
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

    {:ok, result}
  end

  defp do_eval_infix_expr(operator, left, right) do
    result =
      case operator do
        "==" -> left == right
        "!=" -> left != right
        _ -> nil
      end

    {:ok, result}
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
