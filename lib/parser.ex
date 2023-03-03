defmodule Parser do
  alias AST.StringLiteral
  alias AST.CallExpression
  alias AST.FunctionLiteral
  alias AST.BlockStmt
  alias AST.IfExpression

  alias AST.{
    Program,
    LetStmt,
    Identifier,
    ExpressionStmt,
    ReturnStmt,
    IntLiteral,
    PrefixExpression,
    InfixExpression,
    BoolLiteral
  }

  def parse_program(tokens) do
    {_, _, stmts, errors} = do_parse_stmts(tokens, [], [], fn _ -> false end)
    %Program{statements: stmts, errors: errors}
  end

  defp do_parse_stmts([], stmts, errors, _),
    do: {:ok, [], Enum.reverse(stmts), Enum.reverse(errors)}

  defp do_parse_stmts(tokens, stmts, errors, end_fn) do
    if end_fn.(tokens) do
      {:ok, tokens, Enum.reverse(stmts), Enum.reverse(errors)}
    else
      case next_statement(tokens) do
        {:ok, rest, nil} ->
          do_parse_stmts(rest, stmts, errors, end_fn)

        {:ok, rest, stmt} ->
          do_parse_stmts(rest, [stmt | stmts], errors, end_fn)

        {:end, _, _} ->
          {:ok, [], Enum.reverse(stmts), Enum.reverse(errors)}

        {:error, rest, reasons} when is_list(reasons) ->
          do_parse_stmts(rest, stmts, reasons ++ errors, end_fn)

        {:error, rest, reason} ->
          do_parse_stmts(rest, stmts, [reason | errors], end_fn)
      end
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

  defp parse_let_stmt(tokens) do
    with {:ok, _, _} <- expect_token(tokens, :ident),
         {:ok, rest, ident} <- parse_identifier(tokens),
         {:ok, rest, _} <- expect_token(rest, :assign),
         {:ok, rest, expr} <- parse_expression(rest, :lowest) do
      rest = consume_token(rest, :semicolon)
      {:ok, rest, %LetStmt{name: ident, value: expr}}
    end
  end

  defp parse_return_stmt(tokens) do
    with {:ok, rest, expr} <- parse_expression(tokens, :lowest) do
      rest = consume_token(rest, :semicolon)
      {:ok, rest, %ReturnStmt{ret_value: expr}}
    end
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

  defp parse_block_stmt(tokens) do
    {:ok, rest, stmts, errors} =
      do_parse_stmts(tokens, [], [], fn [token | _tokens] ->
        token.type === :rbrace || token.type === :eof
      end)

    with {:ok, rest, _} <- expect_token(rest, :rbrace) do
      case errors do
        [] -> {:ok, rest, %BlockStmt{statements: stmts}}
        _ -> {:error, rest, errors}
      end
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
      :lparen -> :call
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
      true -> &parse_bool_literal/1
      false -> &parse_bool_literal/1
      :lparen -> &parse_group_expression/1
      :if -> &parse_if_expression/1
      :fn -> &parse_function_literal/1
      :string -> &parse_string_literal/1
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
      :lparen -> &parse_call_expression/2
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

  defp parse_bool_literal([token | rest]) do
    {:ok, rest, %BoolLiteral{value: token.type}}
  end

  defp parse_group_expression([_ | rest]) do
    with {:ok, rest, expr} <- parse_expression(rest, :lowest) do
      case rest do
        [%Token{type: :rparen} | rest] -> {:ok, rest, expr}
        _ -> {:error, rest, "unmatched '(' in group expression"}
      end
    end
  end

  defp parse_if_expression([_ | rest]) do
    with {:ok, rest, _} <- expect_token(rest, :lparen),
         {:ok, rest, condition} <- parse_expression(rest, :lowest),
         {:ok, rest, _} <- expect_token(rest, :rparen),
         {:ok, rest, _} <- expect_token(rest, :lbrace),
         {:ok, rest, then} <- parse_block_stmt(rest) do
      case rest do
        [%Token{type: :else} | rest] ->
          with {:ok, rest, _} <- expect_token(rest, :lbrace),
               {:ok, rest, else_branch} <- parse_block_stmt(rest) do
            {:ok, rest, %IfExpression{condition: condition, then: then, else: else_branch}}
          end

        _ ->
          {:ok, rest, %IfExpression{condition: condition, then: then}}
      end
    end
  end

  defp parse_function_literal([_ | rest]) do
    with {:ok, rest, _} <- expect_token(rest, :lparen),
         {:ok, rest, params} <- parse_function_params(rest),
         {:ok, rest, _} <- expect_token(rest, :lbrace),
         {:ok, rest, body} <- parse_block_stmt(rest) do
      {:ok, rest, %FunctionLiteral{params: params, body: body}}
    end
  end

  defp parse_function_params(tokens) do
    do_parse_function_params(tokens, [])
  end

  defp do_parse_function_params([%Token{type: :rparen} | rest], acc),
    do: {:ok, rest, Enum.reverse(acc)}

  defp do_parse_function_params([%Token{type: :comma} | rest], acc),
    do: do_parse_function_params(rest, acc)

  defp do_parse_function_params([%Token{type: :ident, lexeme: lexeme} | rest], acc),
    do: do_parse_function_params(rest, [%Identifier{value: lexeme} | acc])

  defp do_parse_function_params([%Token{lexeme: lexeme} | rest], _acc),
    do: {:error, rest, "Unexpected token '#{lexeme}' when parsing function params"}

  defp parse_call_expression([_token | rest], left) do
    with {:ok, rest, args} <- parse_function_args(rest) do
      {:ok, rest, %CallExpression{function: left, args: args}}
    end
  end

  defp parse_function_args(tokens) do
    do_parse_function_args(tokens, [])
  end

  defp do_parse_function_args([%Token{type: :rparen} | rest], acc),
    do: {:ok, rest, Enum.reverse(acc)}

  defp do_parse_function_args([%Token{type: :comma} | rest], acc) do
    do_parse_function_args(rest, acc)
  end

  defp do_parse_function_args([], _acc), do: {:error, [], "malformed function call missing ')'"}

  defp do_parse_function_args(tokens, acc) do
    with {:ok, rest, expr} <- parse_expression(tokens, :lowest) do
      do_parse_function_args(rest, [expr | acc])
    end
  end

  defp parse_string_literal([token | rest]) do
    {:ok, rest, %StringLiteral{value: token.lexeme}}
  end

  defp expect_token([%Token{type: expected_type} | rest], expected_type), do: {:ok, rest, nil}

  defp expect_token([%Token{lexeme: lexeme} | rest], expected),
    do: {:error, rest, "Unexpected token, got #{lexeme}, expected #{expected}"}

  defp consume_token([%Token{type: expected_type} | rest], expected_type), do: rest
  defp consume_token(tokens, _), do: tokens
end
