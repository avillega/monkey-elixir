defmodule Lexer do
  def tokenize(input) do
    Enum.reverse(do_tokenize(input, []))
  end

  defp do_tokenize("", tokens), do: tokens

  defp do_tokenize(input, tokens) do
    {new_input, token} = next_token(String.trim_leading(input))
    do_tokenize(new_input, [token | tokens])
  end

  defguardp is_digit(ch) when ch in ?0..?9
  defguardp is_alpha(ch) when ch in ?a..?z or ch in ?A..?Z

  @spec next_token(String.t()) :: {String.t(), Token.t()}
  def next_token(<<?!, ch, rest::binary>>) do
    case ch do
      ?= -> {rest, Token.create(:not_eq, "!=")}
      _ -> {<<ch, rest::binary>>, Token.create(:bang, "!")}
    end
  end

  def next_token(<<?=, ch, rest::binary>>) do
    case ch do
      ?= -> {rest, Token.create(:eq, "==")}
      _ -> {<<ch, rest::binary>>, Token.create(:assign, "=")}
    end
  end

  def next_token(<<"(" <> rest>>), do: {rest, Token.create(:lparen, "(")}
  def next_token(<<")" <> rest>>), do: {rest, Token.create(:rparen, ")")}
  def next_token(<<"{" <> rest>>), do: {rest, Token.create(:lbrace, "{")}
  def next_token(<<"}" <> rest>>), do: {rest, Token.create(:rbrace, "}")}
  def next_token(<<"," <> rest>>), do: {rest, Token.create(:comma, ",")}
  def next_token(<<";" <> rest>>), do: {rest, Token.create(:semicolon, ";")}
  def next_token(<<"+" <> rest>>), do: {rest, Token.create(:plus, "+")}
  def next_token(<<"-" <> rest>>), do: {rest, Token.create(:minus, "-")}
  def next_token(<<"*" <> rest>>), do: {rest, Token.create(:star, "*")}
  def next_token(<<"/" <> rest>>), do: {rest, Token.create(:slash, "/")}
  def next_token(<<"<" <> rest>>), do: {rest, Token.create(:lt, "<")}
  def next_token(<<">" <> rest>>), do: {rest, Token.create(:gt, ">")}
  def next_token(<<"fn" <> rest>>), do: {rest, Token.create(:fn, "fn")}
  def next_token(<<"let" <> rest>>), do: {rest, Token.create(:let, "let")}
  def next_token(<<"if" <> rest>>), do: {rest, Token.create(:if, "if")}
  def next_token(<<"else" <> rest>>), do: {rest, Token.create(:else, "else")}
  def next_token(<<"true" <> rest>>), do: {rest, Token.create(true, "true")}
  def next_token(<<"false" <> rest>>), do: {rest, Token.create(false, "false")}
  def next_token(<<"return" <> rest>>), do: {rest, Token.create(:return, "return")}

  def next_token(<<"\"" <> rest>>) do 
    read_string(rest)
  end

  def next_token(input = <<ch, _::binary>>) when is_digit(ch) do
    read_int(input)
  end

  def next_token(input = <<ch, _::binary>>) when is_alpha(ch) do
    read_ident(input)
  end

  def next_token("") do
    {"", Token.create(:eof, "")}
  end

  def next_token(<<ch, rest::binary>>), do: {rest, Token.create(:illegal, ch)}

  defp read_int(input) do
    [_, number, rest] = Regex.split(~r{(\d+)}, input, include_captures: true, parts: 2)
    {rest, Token.create(:int, number)}
  end

  defp read_ident(input) do
    [_, ident, rest] = Regex.split(~r{([A-Za-z]+)}, input, include_captures: true, parts: 2)
    {rest, Token.create(:ident, ident)}
  end

  # The first double-quote has been already consumed
  defp read_string(input) do
    [str, rest] = String.split(input, "\"", parts: 2)
    {rest, Token.create(:string, str)}
  end
end
