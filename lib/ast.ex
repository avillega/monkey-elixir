defmodule AST do
  defmodule Program do
    defstruct type: :program, statements: [], errors: []

    defimpl String.Chars, for: __MODULE__ do
      def to_string(program), do: Enum.join(program.statements)
    end
  end

  # Statements

  defmodule LetStmt do
    @enforce_keys [:name, :value]
    # :name is an Identifier and :value is any Expression 
    defstruct [:name, :value, type: :let_stmt]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(stmt), do: "let #{stmt.name} = #{stmt.value};"
    end
  end

  defmodule ReturnStmt do
    @enforce_keys [:ret_value]
    # :ret_value is an Expression
    defstruct [:ret_value, type: :return_stmt]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(stmt), do: "return #{stmt.ret_value};"
    end
  end

  defmodule ExpressionStmt do
    @enforce_keys [:expression]
    # :expression is an Expression
    defstruct [:expression, type: :expression_stmt]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(stmt) do
        if stmt.expression, do: "#{stmt.expression}", else: ""
      end
    end
  end

  defmodule BlockStmt do
    @enforce_keys [:statements]
    # :expression is an Expression
    defstruct [:statements, type: :block_stmt]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(stmt), do: "{ #{Enum.join(stmt.statements)} }"
    end
  end

  # Expressions

  defmodule Identifier do
    @enforce_keys [:value]
    # :value is a string
    defstruct [:value, type: :ident]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "#{expr.value}"
    end
  end

  defmodule IntLiteral do
    @enforce_keys [:value]
    # :value is an integer
    defstruct [:value, type: :int_literal]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "#{expr.value}"
    end
  end

  defmodule PrefixExpression do
    @enforce_keys [:operator, :right]
    # :operator is string, :right is a expression 
    defstruct [:operator, :right, type: :prefix_expression]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "(#{expr.operator}#{expr.right})"
    end
  end

  defmodule InfixExpression do
    @enforce_keys [:left, :operator, :right]
    # :left is an expression, :operator is a string, :right is a expression
    defstruct [:left, :operator, :right, type: :infix_expression]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "(#{expr.left} #{expr.operator} #{expr.right})"
    end
  end

  defmodule BoolLiteral do
    @enforce_keys [:value]
    # :value is boolean
    defstruct [:value, type: :bool_literal]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "#{expr.value}"
    end
  end

  defmodule IfExpression do
    @enforce_keys [:condition, :then]
    # :condition is an expression, :then is a block stmt, :else is an optional block stmt
    defstruct [:condition, :then, :else, type: :if_expression]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr) do
        else_str = if expr.else, do: "else #{expr.else}", else: ""
        "if#{expr.condition} #{expr.then}#{else_str}"
      end
    end
  end

  defmodule FunctionLiteral do
    @enforce_keys [:params, :body]
    # :params are a list of Identifiers, :body is a block stmt
    defstruct [:params, :body, type: :function_literal]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr) do
        "fn(#{Enum.join(expr.params, ", ")}) #{expr.body}"
      end
    end
  end

  defmodule CallExpression do
    @enforce_keys [:function, :args]
    # :function is an expression, :args is a list of expressions
    defstruct [:function, :args, type: :call_expression]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr) do
        "#{expr.function}(#{Enum.join(expr.args, ", ")})"
      end
    end
  end

  defmodule StringLiteral do
    @enforce_keys [:value]
    # :value is boolean
    defstruct [:value, type: :string_literal]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "\"#{expr.value}\""
    end
  end

  defmodule ArrayLiteral do
    @enforce_keys [:expressions]
    # :value is boolean
    defstruct [:expressions, type: :array_literal]

    defimpl String.Chars, for: __MODULE__ do
      def to_string(expr), do: "[#{Enum.join(expr.expressions, ",")}]"
    end
  end
end
