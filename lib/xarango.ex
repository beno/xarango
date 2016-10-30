defmodule Xarango do
end

defmodule Xarango.Util do
  
  def name_from(module) do
    module
    |> Module.split
    |> Enum.join("")
    |> Macro.underscore
  end
  
end