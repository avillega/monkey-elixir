defmodule Repl do
  def loop() do
    input = IO.gets(">> ")
    program = input |> Lexer.tokenize |> Parser.parse_program

    s = case program.errors do
      [] -> "#{program}"
      _ -> errors_string(program.errors) 
    end

    IO.puts(s)
    loop()
  end

  defp errors_string(errors), do: "Parser errors: #{Enum.join(errors, "\n")}"
end
