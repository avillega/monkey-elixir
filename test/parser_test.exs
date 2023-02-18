defmodule ParserTest do
  use ExUnit.Case
  doctest Parser
  alias AST.InfixExpression
  alias AST.BoolLiteral
  alias AST.Identifier
  alias AST.{LetStmt, IntLiteral}

  test "parse let statements" do
    input = """
      let x = 5;
      let y = 10;
      let foobar = 838383;
    """

    expectedIdentifiers = ["x", "y", "foobar"]

    tokens = Lexer.tokenize(input)
    program = Parser.parse_program(tokens)
    assert program.errors == []
    assert Enum.count(program.statements) === Enum.count(expectedIdentifiers)

    Enum.zip(program.statements, expectedIdentifiers)
    |> Enum.each(fn {stmt, expected_ident} ->
      test_let_stmt(stmt, expected_ident)
    end)
  end

  test "parse return statements" do
    input = """
      return 5;
      return 10;
      return 838383;
    """

    tokens = Lexer.tokenize(input)
    program = Parser.parse_program(tokens)

    assert Enum.count(program.statements) === 3
    assert program.errors === []

    Enum.each(program.statements, fn stmt ->
      assert stmt.type === :return_stmt
    end)
  end

  test "parse identifier expressions" do
    input = "foobar;"
    tokens = Lexer.tokenize(input)
    program = Parser.parse_program(tokens)

    assert Enum.count(program.statements) === 1
    assert program.errors === []

    [stmt] = program.statements
    assert stmt.type === :expression_stmt
    assert stmt.expression.type === :ident
    assert stmt.expression.value === "foobar"
  end

  test "parse integer literals" do
    input = "5;"
    tokens = Lexer.tokenize(input)
    program = Parser.parse_program(tokens)

    assert Enum.count(program.statements) === 1
    assert program.errors === []

    [stmt] = program.statements
    assert stmt.type === :expression_stmt
    test_int_literal(stmt.expression, 5)
  end

  test "parse prefix expressions" do
    tests = [
      {"!5;", {"!", 5}},
      {"-15;", {"-", 15}},
      {"!true", {"!", true}},
      {"!false", {"!", false}}
    ]

    Enum.each(tests, fn
      {input, {op, expected_right}} ->
        tokens = Lexer.tokenize(input)
        program = Parser.parse_program(tokens)

        assert Enum.count(program.statements) === 1
        assert program.errors === []

        [stmt] = program.statements
        assert stmt.type === :expression_stmt
        assert stmt.expression.type === :prefix_expression
        assert stmt.expression.operator === op
        test_literal_expression(stmt.expression.right, expected_right)
    end)
  end

  test "parse infix expressions" do
    tests = [
      {"5 + 4;", {5, "+", 4}},
      {"15 - 10;", {15, "-", 10}},
      {"9 * 10;", {9, "*", 10}},
      {"7 / 45;", {7, "/", 45}},
      {"3 < 6;", {3, "<", 6}},
      {"6 > 3;", {6, ">", 3}},
      {"100 == 100;", {100, "==", 100}},
      {"42 != 43;", {42, "!=", 43}},
      {"true == true", {true, "==", true}},
      {"false != true", {false, "!=", true}},
      {"false == false", {false, "==", false}}
    ]

    Enum.each(tests, fn
      {input, {expected_left, op, expected_right}} ->
        tokens = Lexer.tokenize(input)
        program = Parser.parse_program(tokens)

        assert program.errors === []
        assert Enum.count(program.statements) === 1

        [stmt] = program.statements
        assert stmt.type === :expression_stmt
        test_infix_expression(stmt.expression, expected_left, op, expected_right)
    end)
  end

  test "operator precedence parsing" do
    tests = [
      {"-a * b", "((-a) * b)"},
      {"!-a", "(!(-a))"},
      {"a + b + c", "((a + b) + c)"},
      {"a + b * c", "(a + (b * c))"},
      {"a + b - c", "((a + b) - c)"},
      {"a * b * c", "((a * b) * c)"},
      {"a * b / c", "((a * b) / c)"},
      {"a + b / c", "(a + (b / c))"},
      {"a + b * c - d / e - f", "(((a + (b * c)) - (d / e)) - f)"},
      {"3 + 4; -5 + 5", "(3 + 4)((-5) + 5)"},
      {"5 > 4 == 3 < 4", "((5 > 4) == (3 < 4))"},
      {"5 < 4 != 3 > 4", "((5 < 4) != (3 > 4))"},
      {"3 + 4 * 5 == 3 * 1 + 4 * 5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
      {"3+4*5 == 3*1+4*5", "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"},
      {"true", "true"},
      {"false", "false"},
      {"3 < 4 == true", "((3 < 4) == true)"},
      {"3 > 4 == false", "((3 > 4) == false)"},
      {"1 + (2 + 3) + 4", "((1 + (2 + 3)) + 4)"},
      {"(5 + 5) * 2", "((5 + 5) * 2)"},
      {"2 / (5 + 5)", "(2 / (5 + 5))"},
      {"-(5 + 5)", "(-(5 + 5))"},
      {"!(true == true)", "(!(true == true))"},
      {"1 + add(b * c) + d", "((1 + add((b * c))) + d)"},
      {"add(a, b, add(6 * 7))", "add(a, b, add((6 * 7)))"},
      {"add((a + b) * c, d)", "add(((a + b) * c), d)"}
    ]

    Enum.each(tests, fn {input, expected} ->
      tokens = Lexer.tokenize(input)
      program = Parser.parse_program(tokens)
      assert program.errors === []
      assert "#{program}" == expected
    end)
  end

  test "parse boolean literal" do
    input = "true; false;"
    expected = [true, false]

    tokens = Lexer.tokenize(input)
    program = Parser.parse_program(tokens)
    assert program.errors === []
    assert Enum.count(program.statements) === Enum.count(expected)

    Enum.zip(program.statements, expected)
    |> Enum.each(fn {stmt, expected} -> test_bool_literal(stmt.expression, expected) end)
  end

  test "parse if expressions" do
    input = "if (x < y) { x }"

    program = input |> Lexer.tokenize() |> Parser.parse_program()
    assert program.errors === []

    [stmt] = program.statements
    assert stmt.type === :expression_stmt
    assert stmt.expression.type === :if_expression
    test_infix_expression(stmt.expression.condition, "x", "<", "y")

    then_branch = stmt.expression.then
    assert then_branch.type === :block_stmt
    test_identifier(hd(then_branch.statements).expression, "x")

    assert stmt.expression.else === nil
  end

  test "parse if-else expressions" do
    input = "if (x < y) { x } else { y }"

    program = input |> Lexer.tokenize() |> Parser.parse_program()
    assert program.errors === []

    [stmt] = program.statements
    assert stmt.type === :expression_stmt
    assert stmt.expression.type === :if_expression
    test_infix_expression(stmt.expression.condition, "x", "<", "y")

    then_branch = stmt.expression.then
    assert then_branch.type === :block_stmt
    test_identifier(hd(then_branch.statements).expression, "x")

    else_branch = stmt.expression.else
    assert else_branch.type === :block_stmt
    test_identifier(hd(else_branch.statements).expression, "y")
  end

  test "parse function literal" do
    input = "fn(x, y) {x + y; }"

    program = input |> Lexer.tokenize() |> Parser.parse_program()
    assert program.errors === []

    [stmt] = program.statements
    assert stmt.type === :expression_stmt

    function = stmt.expression
    assert function.type === :function_literal

    assert length(function.params) === 2
    [param1, param2] = function.params
    test_identifier(param1, "x")
    test_identifier(param2, "y")

    [body] = function.body.statements
    test_infix_expression(body.expression, "x", "+", "y")
  end

  test "parse function literal params edge cases" do
    tests = [
      {"fn() {}", []},
      {"fn(x) {}", ["x"]},
      {"fn(x, y) {}", ["x", "y"]},
      {"fn(x, y, z) {}", ["x", "y", "z"]}
    ]

    Enum.each(tests, fn {input, expected_identifiers} ->
      program = input |> Lexer.tokenize() |> Parser.parse_program()
      assert program.errors === []

      [stmt] = program.statements
      assert stmt.type === :expression_stmt

      function = stmt.expression
      assert function.type === :function_literal

      assert length(function.params) === length(expected_identifiers)

      Enum.zip(function.params, expected_identifiers)
      |> Enum.each(fn {ident, expected_ident} -> test_identifier(ident, expected_ident) end)
    end)
  end

  test "parse call expression" do
    input = "add(1, 2 * 3, 4 + 5);"

    program = input |> Lexer.tokenize() |> Parser.parse_program()
    assert program.errors === []

    [stmt] = program.statements
    assert stmt.type === :expression_stmt

    call = stmt.expression
    assert call.type === :call_expression

    test_literal_expression(call.function, "add")

    assert length(call.args) === 3
    [arg1, arg2, arg3] = call.args
    test_literal_expression(arg1, 1)
    test_infix_expression(arg2, 2, "*", 3)
    test_infix_expression(arg3, 4, "+", 5)
  end

  defp test_let_stmt(stmt = %LetStmt{}, identifier_name) do
    assert stmt.type === :let_stmt
    assert stmt.name.value === identifier_name
  end

  defp test_int_literal(literal = %IntLiteral{}, expected_val) do
    assert literal.type === :int_literal
    assert literal.value === expected_val
  end

  defp test_identifier(ident = %Identifier{}, value) do
    assert ident.type === :ident
    assert ident.value === value
  end

  defp test_bool_literal(literal = %BoolLiteral{}, expected_val) do
    assert literal.type === :bool_literal
    assert literal.value === expected_val
  end

  defp test_literal_expression(expr, expected) do
    case expr do
      %IntLiteral{} -> test_int_literal(expr, expected)
      %Identifier{} -> test_identifier(expr, expected)
      %BoolLiteral{} -> test_bool_literal(expr, expected)
    end
  end

  defp test_infix_expression(expr = %InfixExpression{}, left, op, right) do
    assert expr.type === :infix_expression
    test_literal_expression(expr.left, left)
    assert expr.operator === op
    test_literal_expression(expr.right, right)
  end
end
