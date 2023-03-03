defmodule LexerTest do
  use ExUnit.Case
  doctest Lexer

  test "can lex the input" do
    input = "!=!{}(fn);"

    expected = [
      %Token{type: :not_eq, lexeme: "!="},
      %Token{type: :bang, lexeme: "!"},
      %Token{type: :lbrace, lexeme: "{"},
      %Token{type: :rbrace, lexeme: "}"},
      %Token{type: :lparen, lexeme: "("},
      %Token{type: :fn, lexeme: "fn"},
      %Token{type: :rparen, lexeme: ")"},
      %Token{type: :semicolon, lexeme: ";"}
    ]

    tokens = Lexer.tokenize(input)
    assert length(tokens) == length(expected)

    Enum.zip(expected, tokens)
    |> Enum.each(fn {exp, tok} -> assert exp === tok end)
  end

  test "lexes monkey lang input" do
    input = """
    let five = 5;
    let ten = 10;

    let add = fn(x, y) {
      x + y;
    };

    let result = add(five, ten);
    !-/*5;
    5 < 10 > 5;

    if (5 < 10) {
      return true;
    } else {
      return false;
    }

    10 == 10;
    10 != 9;
    "foobar";
    "foo bar";
    [10 2 "hello"];
    """

    expected = [
      %Token{type: :let, lexeme: "let"},
      %Token{type: :ident, lexeme: "five"},
      %Token{type: :assign, lexeme: "="},
      %Token{type: :int, lexeme: "5"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :let, lexeme: "let"},
      %Token{type: :ident, lexeme: "ten"},
      %Token{type: :assign, lexeme: "="},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :let, lexeme: "let"},
      %Token{type: :ident, lexeme: "add"},
      %Token{type: :assign, lexeme: "="},
      %Token{type: :fn, lexeme: "fn"},
      %Token{type: :lparen, lexeme: "("},
      %Token{type: :ident, lexeme: "x"},
      %Token{type: :comma, lexeme: ","},
      %Token{type: :ident, lexeme: "y"},
      %Token{type: :rparen, lexeme: ")"},
      %Token{type: :lbrace, lexeme: "{"},
      %Token{type: :ident, lexeme: "x"},
      %Token{type: :plus, lexeme: "+"},
      %Token{type: :ident, lexeme: "y"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :rbrace, lexeme: "}"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :let, lexeme: "let"},
      %Token{type: :ident, lexeme: "result"},
      %Token{type: :assign, lexeme: "="},
      %Token{type: :ident, lexeme: "add"},
      %Token{type: :lparen, lexeme: "("},
      %Token{type: :ident, lexeme: "five"},
      %Token{type: :comma, lexeme: ","},
      %Token{type: :ident, lexeme: "ten"},
      %Token{type: :rparen, lexeme: ")"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :bang, lexeme: "!"},
      %Token{type: :minus, lexeme: "-"},
      %Token{type: :slash, lexeme: "/"},
      %Token{type: :star, lexeme: "*"},
      %Token{type: :int, lexeme: "5"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :int, lexeme: "5"},
      %Token{type: :lt, lexeme: "<"},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :gt, lexeme: ">"},
      %Token{type: :int, lexeme: "5"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :if, lexeme: "if"},
      %Token{type: :lparen, lexeme: "("},
      %Token{type: :int, lexeme: "5"},
      %Token{type: :lt, lexeme: "<"},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :rparen, lexeme: ")"},
      %Token{type: :lbrace, lexeme: "{"},
      %Token{type: :return, lexeme: "return"},
      %Token{type: true, lexeme: "true"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :rbrace, lexeme: "}"},
      %Token{type: :else, lexeme: "else"},
      %Token{type: :lbrace, lexeme: "{"},
      %Token{type: :return, lexeme: "return"},
      %Token{type: false, lexeme: "false"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :rbrace, lexeme: "}"},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :eq, lexeme: "=="},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :not_eq, lexeme: "!="},
      %Token{type: :int, lexeme: "9"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :string, lexeme: "foobar"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :string, lexeme: "foo bar"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :lbracket, lexeme: "["},
      %Token{type: :int, lexeme: "10"},
      %Token{type: :int, lexeme: "2"},
      %Token{type: :int, lexeme: "hello"},
      %Token{type: :rbracket, lexeme: "]"},
      %Token{type: :semicolon, lexeme: ";"},
      %Token{type: :eof, lexeme: ""}
    ]

    tokens = Lexer.tokenize(input)
    assert length(tokens) == length(expected)

    Enum.zip(expected, tokens)
    |> Enum.each(fn {exp, tok} -> assert exp === tok end)
  end
end
