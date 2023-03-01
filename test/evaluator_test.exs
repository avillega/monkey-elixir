defmodule EvaluatorTest do
  use ExUnit.Case
  doctest Evaluator

  alias Evaluator.Env

  test "eval basic literal" do
    tests = [
      {"5", 5},
      {"10", 10},
      {"true", true},
      {"false", false},
      {"-5", -5},
      {"-12", -12}
    ]

    eval_and_test(tests)
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

    eval_and_test(tests)
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

    eval_and_test(tests)
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

    eval_and_test(tests)
  end

  test "eval return stmts" do
    tests = [
      {"return 10;", 10},
      {"return 10; 5;", 10},
      {"return 2 * 5; 5;", 10},
      {"return 10; 5;", 10},
      {"9; return 10; 5;", 10},
      {"if (10 > 1) {
          if (true) {
            return 10;
          }
          return 1;
        }", 10}
    ]

    eval_and_test(tests)
  end

  test "error handling" do
    tests = [
      {"5 + true", "unknown operator: + for left: 5 and right: true"},
      {"5 + true; 5;", "unknown operator: + for left: 5 and right: true"},
      {"-true", "unknown operator: - for true"},
      {"true + true", "unknown operator: + for left: true and right: true"},
      {"5; 5 + true; 10;", "unknown operator: + for left: 5 and right: true"},
      {"if (10 > 1) { true + false; }", "unknown operator: + for left: true and right: false"},
      {"if (10 > 1) {
          if (true) {
            return true + false;
          }
          return 1;
        }", "unknown operator: + for left: true and right: false"},
      {"foobar", "identifier not found: foobar"}
    ]

    eval_error(tests)
  end

  test "eval let statements" do
    tests = [
      {"let a = 5; a;", 5},
      {"let a = 5 * 5; a;", 25},
      {"let a = 5; let b = a; b;", 5},
      {"let a = 5; let b = a; let c = a + b + 5; c;", 15}
    ]

    eval_and_test(tests)
  end

  test "function struct" do
    tests = [
      {"fn() {  2; }", %{params: [], body: "{ 2 }"}},
      {"fn(x) { x + 2; }", %{params: ["x"], body: "{ (x + 2) }"}},
      {"fn(x, y) { x + y; }", %{params: ["x", "y"], body: "{ (x + y) }"}}
    ]

    Enum.each(tests, fn {input, expected_fn} ->
      evaluated = input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval(%Env{})
      assert evaluated.params === expected_fn[:params]
      assert "#{evaluated.body}" === expected_fn[:body]
    end)
  end

  defp eval_and_test(tests) do
    Enum.each(tests, fn {input, expected} ->
      {:ok, evaluated, _env} =
        input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval(%Env{})

      assert evaluated === expected
    end)
  end

  defp eval_error(tests) do
    Enum.each(tests, fn {input, expected} ->
      {:error, evaluated, _env} =
        input |> Lexer.tokenize() |> Parser.parse_program() |> Evaluator.eval(%Env{})

      assert evaluated === expected
    end)
  end
end
