defmodule ASTTest do
  alias AST.{Program, LetStmt, Identifier}
  use ExUnit.Case
  doctest AST

  test "tests AST to_string" do
    program = %Program{
      statements: [
        %LetStmt{
          name: %Identifier{
            value: "myVar"
          },
          value: %Identifier{
            value: "anotherVal"
          }
        }
      ]
    }

    assert "#{program}" === "let myVar = anotherVal;"
  end
end
