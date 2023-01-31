defmodule Token do
  @enforce_keys [:type, :lexeme]
  defstruct [:type, :lexeme]

  @types [
    :ident,
    :assign,
    :bang,
    :eq,
    :not_eq,
    :lparen,
    :rparen,
    :lbrace,
    :rbrace,
    :comma,
    :semicolon,
    :plus,
    :minus,
    :star,
    :slash,
    :lt,
    :gt,
    :fn,
    :let,
    :if,
    :else,
    true,
    false,
    :return,
    :int,
    :eof,
    :illegal
  ]

  def create(type, lexeme) do
    if type in @types do
      %__MODULE__{type: type, lexeme: lexeme}
    else
      raise "Can not create token if type: #{type}."
    end
  end
end
