defmodule Repl do
  alias Evaluator.Env

  def loop(env \\ %Env{}) do
    input = IO.gets(">> ")
    program = input |> Lexer.tokenize() |> Parser.parse_program()

    {s, env} =
      case program.errors do
        [] ->
          with {:ok, val, env} <- Evaluator.eval(program, env) do
            {"#{val}", env}
          else
            {:error, msg, env} -> {msg, env}
          end

        _ ->
          {errors_string(program.errors), env}
      end

    IO.puts(s)
    loop(env)
  end

  defp errors_string(errors), do: "Parser errors: #{Enum.join(errors, "\n")}"
end
