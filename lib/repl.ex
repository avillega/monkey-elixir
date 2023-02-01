defmodule Repl do
  def loop() do
    input = IO.gets(">> ")
    tokens = Lexer.tokenize(input)
    Enum.each(tokens, &IO.inspect/1)
    loop()
  end
end
