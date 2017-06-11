defmodule Xarango.Schema do
  
  defmacro schema(fields) do
    quote do
      @schema unquote(fields)
      def schema, do: @schema
      def keys, do: Keyword.keys(schema())
      def keys_as_string, do: Enum.map(keys(), fn key -> Atom.to_string(key) end)
    end
  end
  
  defmacro __using__(options\\[]) do
    quote do
      Module.register_attribute __MODULE__, :schema, []
      import Xarango.Schema, only: [schema: 1]
    end
  end

  
end
