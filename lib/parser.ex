defmodule Parser do
  alias AST.{
    Program,
    LetStmt,
    Identifier,
    ExpressionStmt,
    ReturnStmt,
    IntLiteral,
    PrefixExpression,
    InfixExpression
  }

  def parse_program(tokens) do
    {_, stmts, errors} = do_parse_program(tokens, [], [])
    %Program{statements: Enum.reverse(stmts), errors: errors}
  end

  defp do_parse_program([], stmts, errors), do: {:ok, stmts, errors}

  defp do_parse_program(tokens, stmts, errors) do
    case next_statement(tokens) do
      {:ok, rest, nil} -> do_parse_program(rest, stmts, errors)
      {:ok, rest, stmt} -> do_parse_program(rest, [stmt | stmts], errors)
      {:end, _, _} -> {:ok, stmts, errors}
      {:error, rest, reason} -> do_parse_program(rest, stmts, [reason | errors])
    end
  end

  defp next_statement([%Token{type: :eof}]) do
    {:end, [], nil}
  end

  defp next_statement([%Token{type: :let} | rest]) do
    parse_let_stmt(rest)
  end

  defp next_statement([%Token{type: :return} | rest]) do
    parse_return_stmt(rest)
  end

  defp next_statement(tokens) do
    parse_expression_stmt(tokens)
  end

  defp parse_let_stmt([%Token{type: :ident, lexeme: lexeme}, %Token{type: :assign} | rest]) do
    identifier = %Identifier{value: lexeme}

    # TODO: skip the expressions until we can parse it
    rest =
      Enum.drop_while(rest, fn
        %Token{type: :semicolon} -> false
        _ -> true
      end)
      |> Enum.drop(1)

    {:ok, rest, %LetStmt{name: identifier, value: nil}}
  end

  defp parse_let_stmt([%Token{type: :ident}, %Token{lexeme: lexeme} | rest]) do
    {:error, rest,
     "Unexpected token #{lexeme} when parsing a let statemet expected an assigment (=)."}
  end

  defp parse_let_stmt([%Token{lexeme: lexeme} | rest]) do
    {:error, rest,
     "Unexpected token #{lexeme} when parsing a let statemet expected an identifier."}
  end

  defp parse_return_stmt(tokens) do
    # TODO: skip the expressions until we can parse it
    rest =
      Enum.drop_while(tokens, fn
        %Token{type: :semicolon} -> false
        _ -> true
      end)
      |> Enum.drop(1)

    {:ok, rest, %ReturnStmt{ret_value: nil}}
  end

  defp parse_expression_stmt(tokens) do
    # payload can be an expression or the error context
    {code, rest, payload} = parse_expression(tokens, :lowest)

    rest =
      case rest do
        [%Token{type: :semicolon} | rest] -> rest
        rest -> rest
      end

    case code do
      :ok -> {:ok, rest, %ExpressionStmt{expression: payload}}
      :error -> {:error, rest, payload}
    end
  end

  defp precedence_value(prec) do
    case prec do
      :lowest -> 0
      :equals -> 1
      :less_greater -> 2
      :sum -> 3
      :product -> 4
      :prefix -> 5
      :call -> 6
    end
  end

  defp prec_lessthan(p1, p2) do
    precedence_value(p1) < precedence_value(p2)
  end

  defp operator_precedence(token_type) do
    case token_type do
      :eq -> :equals
      :not_eq -> :equals
      :lt -> :less_greater
      :gt -> :less_greater
      :plus -> :sum
      :minus -> :sum
      :star -> :product
      :slash -> :product
      _ -> :lowest
    end
  end

  defp parse_expression(tokens = [token | rest], precedence) do
    prefix_fn = prefix_fns(token.type)

    if !prefix_fn do
      {:error, rest, "no prefix parse fn for '#{token.lexeme}' found"}
    else
      with {:ok, rest, left_expr} <- prefix_fn.(tokens) do
        calc_left_expr(rest, left_expr, precedence)
      end
    end
  end

  defp calc_left_expr([], left_expr, _), do: {:ok, [], left_expr}

  defp calc_left_expr(tokens = [token | _rest], left_expr, precedence) do
    infix_fn = infix_fns(token.type)

    calc_next? =
      token.type !== :semicolon && prec_lessthan(precedence, operator_precedence(token.type)) &&
        infix_fn

    cond do
      calc_next? ->
        with {:ok, rest, left_expr} <- infix_fn.(tokens, left_expr) do
          calc_left_expr(rest, left_expr, precedence)
        end

      :else ->
        {:ok, tokens, left_expr}
    end
  end

  defp prefix_fns(token_type) do
    case token_type do
      :ident -> &parse_identifier/1
      :int -> &parse_int_literal/1
      :bang -> &parse_prefix_expression/1
      :minus -> &parse_prefix_expression/1
      _ -> nil
    end
  end

  defp infix_fns(token_type) do
    case token_type do
      :eq -> &parse_infix_expression/2
      :not_eq -> &parse_infix_expression/2
      :lt -> &parse_infix_expression/2
      :gt -> &parse_infix_expression/2
      :plus -> &parse_infix_expression/2
      :minus -> &parse_infix_expression/2
      :star -> &parse_infix_expression/2
      :slash -> &parse_infix_expression/2
      _ -> nil
    end
  end

  defp parse_identifier([token | rest]) do
    {:ok, rest, %Identifier{value: token.lexeme}}
  end

  defp parse_int_literal([token | rest]) do
    case Integer.parse(token.lexeme) do
      {num, ""} -> {:ok, rest, %IntLiteral{value: num}}
      _ -> {:error, rest, "couldn't parse #{token.literal} as an integer"}
    end
  end

  defp parse_prefix_expression([token | rest]) do
    with {:ok, rest, expr} <- parse_expression(rest, :prefix) do
      {:ok, rest, %PrefixExpression{operator: token.lexeme, right: expr}}
    end
  end

  defp parse_infix_expression([token | rest], left) do
    with {:ok, rest, right} <- parse_expression(rest, operator_precedence(token.type)) do
      {:ok, rest, %InfixExpression{left: left, operator: token.lexeme, right: right}}
    end
  end
end