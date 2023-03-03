defmodule Evaluator do
  defmodule Builtins do
    def len(args) do
      case args do
        [s] when is_binary(s) -> {:ok, String.length(s)}
        [_] -> {:error, "argument for len not supported"}
        _ -> {:error, "unexpected number of args for len"}
      end
    end
  end

  @builtins MapSet.new([:len])

  defmodule Env do
    # parent is another Env, m is the environment map
    defstruct parent: nil, m: %{}
  end

  defmodule Fn do
    @enforce_keys [:params, :body, :env]
    defstruct [:params, :body, :env]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(func) do
        "fn(#{Enum.join(func.params, ", ")})\n#{func.body}"
      end
    end
  end

  def eval(node, env = %Env{}) do
    do_eval(node, env)
  end

  defp do_eval(nil, env = %Env{}), do: {:ok, nil, env}

  defp do_eval(node, env = %Env{}) do
    case node.type do
      :program -> eval_program(node.statements, env)
      :block_stmt -> eval_block(node.statements, env)
      :expression_stmt -> do_eval(node.expression, env)
      :return_stmt -> eval_return_stmt(node, env)
      :let_stmt -> eval_let_stmt(node, env)
      :int_literal -> {:ok, node.value, env}
      :bool_literal -> {:ok, node.value, env}
      :prefix_expression -> eval_prefix_expr(node, env)
      :infix_expression -> eval_infix_expr(node, env)
      :if_expression -> eval_if_expression(node, env)
      :ident -> eval_ident(node, env)
      :function_literal -> eval_function_literal(node, env)
      :call_expression -> eval_call_expression(node, env)
      :string_literal -> eval_string_literal(node, env)
      _ -> raise "unimplemented for #{node.type}"
    end
  end

  defp eval_program([stmt | rest], env) do
    with {:ok, val, env} <- do_eval(stmt, env) do
      if rest != [] do
        eval_program(rest, env)
      else
        {:ok, val, env}
      end
    else
      {:ret, val, env} -> {:ok, val, env}
      err -> err
    end
  end

  defp eval_block([stmt | rest], env) do
    with {:ok, val, env} <- do_eval(stmt, env) do
      if rest != [], do: eval_block(rest, env), else: {:ok, val, env}
    end
  end

  defp eval_return_stmt(stmt, env) do
    with {:ok, val, env} <- do_eval(stmt.ret_value, env), do: {:ret, val, env}
  end

  defp eval_let_stmt(stmt, env) do
    with {:ok, val, env} <- do_eval(stmt.value, env) do
      env = Map.update!(env, :m, &Map.put(&1, stmt.name.value, val))
      {:ok, nil, env}
    end
  end

  defp eval_prefix_expr(node, env) do
    with {:ok, right, env} <- do_eval(node.right, env) do
      case node.operator do
        "!" -> {:ok, !right, env}
        "-" when is_integer(right) -> {:ok, -right, env}
        _ -> {:error, "unknown operator: #{node.operator} for #{node.right}", env}
      end
    end
  end

  defp eval_infix_expr(node, env) do
    with {:ok, left, env} <- do_eval(node.left, env),
         {:ok, right, env} <- do_eval(node.right, env),
         val when val !== :error <- do_eval_infix_expr(node.operator, left, right) do
      {:ok, val, env}
    else
      :error ->
        {:error,
         "unknown operator: #{node.operator} for left: #{node.left} and right: #{node.right}",
         env}
    end
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
      _ -> :error
    end
  end

  defp do_eval_infix_expr("+", left, right) when is_binary(left) and is_binary(right) do
    left <> right
  end

  defp do_eval_infix_expr(operator, left, right) do
    case operator do
      "==" -> left == right
      "!=" -> left != right
      _ -> :error
    end
  end

  defp eval_if_expression(node, env) do
    with {:ok, condition, env} <- do_eval(node.condition, env) do
      if is_truthy(condition) do
        do_eval(node.then, env)
      else
        do_eval(node.else, env)
      end
    end
  end

  defp eval_ident(node, env) do
    {code, val} = do_eval_ident(node, env)
    {code, val, env}
  end

  defp do_eval_ident(node, env) do
    case Map.get(env.m, node.value, :not_there) do
      :not_there when env.parent !== nil ->
        do_eval_ident(node, env.parent)

      :not_there ->
        atom = String.to_atom(node.value)

        if function_exported?(Builtins, atom, 1) do
          {:ok, {:builtin, atom}}
        else
          {:error, "identifier not found: #{node.value}"}
        end

      val ->
        {:ok, val}
    end
  end

  defp eval_function_literal(node, env) do
    {:ok,
     %Fn{
       params: Enum.map(node.params, & &1.value),
       body: node.body,
       env: env
     }, env}
  end

  defp create_callee(func = %Fn{}) do
    {:ok,
     fn args ->
       new_m = Enum.zip(func.params, args) |> Map.new(& &1)
       extended_env = %Env{parent: func.env, m: new_m}
       do_eval(func.body, extended_env)
     end}
  end

  defp create_callee({:builtin, name}) do
    {:ok,
     fn args ->
       {code, result} = apply(Builtins, name, [args])
       {code, result, nil}
     end}
  end

  defp create_callee(_), do: {:error, "Callee is not a callable function"}

  defp eval_call_expression(node, env) do
    with {:ok, val, _env} <- do_eval(node.function, env),
         {:ok, callee} <- create_callee(val),
         {:ok, args, _env} <- eval_args(node.args, env),
         {:ok, result, _} <- callee.(args) do
      {:ok, result, env}
    else
      {:ret, val, _} -> {:ok, val, env}
      {:error, msg} -> {:error, msg, env}
      err -> err
    end
  end

  defp eval_args(expressions, env) do
    result =
      Enum.reduce_while(expressions, {:ok, []}, fn expr, {:ok, acc} ->
        with {:ok, val, _} <- do_eval(expr, env) do
          {:cont, {:ok, [val | acc]}}
        else
          {:error, msg, _} -> {:halt, :error, msg}
        end
      end)

    case result do
      {:ok, acc} -> {:ok, Enum.reverse(acc), env}
      {:error, msg} -> {:error, "error evaluating function args: #{msg}", env}
    end
  end

  def eval_string_literal(expr, env) do
    {:ok, expr.value, env}
  end

  defp is_truthy(val) do
    case val do
      nil -> false
      false -> false
      _ -> true
    end
  end
end
