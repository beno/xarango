defmodule SchemaTest do
  use ExUnit.Case
  
  test "schema document" do
    
    assert SchemaTestDocument.schema == [name: :string, age: :integer]
    assert SchemaTestDocument.keys == [:name, :age]
    assert SchemaTestDocument.keys_as_string == ["name", "age"]
    
  end
  
  test "schema node" do
    
    assert SchemaTestNode.schema == [name: :string, age: :integer]
    assert SchemaTestNode.keys == [:name, :age]
    assert SchemaTestNode.keys_as_string == ["name", "age"]
    
  end



end

defmodule SchemaTestDocument do
  use Xarango.Domain.Document
  
  schema name: :string, age: :integer
  
end

defmodule SchemaTestNode do
  use Xarango.Domain.Node

  schema name: :string, age: :integer

end

