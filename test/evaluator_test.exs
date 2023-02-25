defmodule EvaluatorTest do
  use ExUnit.Case
  doctest Evaluator

  test "eval basic literal" do
    tests = [
      {"5", 5},
      {"10", 10},
      {"true", true},
      {"false", false},
      {"-5", -5},
      {"-12", -12}
    ]

    Enum.each(tests, fn {input, expected} ->
      evaluated = input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval()
      assert evaluated === expected
    end)
  end

  test "eval bang operator" do
    tests = [
      {"!5", false},
      {"!true", false},
      {"!false", true},
      {"!!5", true},
      {"!!true", true},
      {"!!false", false}
    ]

    Enum.each(tests, fn {input, expected} ->
      evaluated = input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval()
      assert evaluated === expected
    end)
  end

  test "eval infix operations" do
    tests = [
      {"50 + 100", 150},
      {"3 * 3 * 3 + 10", 37},
      {"2 * (5 + 10)", 30},
      {"5 * 2 + 10", 20},
      {"50 / 2 * 2 - 10", 40},
      {"1 < 2", true},
      {"1 > 2", false},
      {"1 < 1", false},
      {"1 > 1", false},
      {"1 == 2", false},
      {"1 == 1", true},
      {"1 != 2", true},
      {"1 != 1", false},
      {"true == true", true},
      {"true == false", false},
      {"true != true", false},
      {"true != false", true},
      {"(1 < 2) == true", true},
      {"(1 < 2) == false", false},
      {"(1 > 2) == true", false},
      {"(1 > 2) == false", true}
    ]

    Enum.each(tests, fn {input, expected} ->
      evaluated = input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval()
      assert evaluated === expected
    end)
  end

  test "eval if else expressions" do
    tests = [
      {"if (true) { 10 }", 10},
      {"if (false) { 10 }", nil},
      {"if (1) { 10 }", 10},
      {"if (1 < 2) { 10 }", 10},
      {"if (1 > 2) { 10 }", nil},
      {"if (1 < 2) { 10 } else { 20 }", 10},
      {"if (1 > 2) { 10 } else { 20 }", 20}
    ]

    Enum.each(tests, fn {input, expected} ->
      evaluated = input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval()
      assert evaluated === expected
    end)
  end

  test "eval return stmts" do
    tests = [
      # {"return 10;", 10},
      # {"return 10; 5;", 10},
      # {"return 2 * 5; 5;", 10},
      # {"return 10; 5;", 10},
      # {"9; return 10; 5;", 10},
      {"if (10 > 1) {
          if (true) {
            return 10;
          }
          return 1;
        }", 10}
    ]

    Enum.each(tests, fn {input, expected} ->
      evaluated = input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval()
      assert evaluated === expected
    end)
  end
end
