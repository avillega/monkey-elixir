defmodule Builtins do
  def len(args) do
    case args do
      [s] when is_binary(s) -> {:ok, String.length(s)}
      [_] -> {:error, "argument for len not supported"}
      _ -> {:error, "unexpected number of args for len"}
    end
  end
end
