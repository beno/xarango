defmodule UtilTest do
  use ExUnit.Case
  
  alias Xarango.Util
  
  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      Xarango.Collection.__destroy_all()
    end
  end
  
  test "domain node to json" do
    source = UtilTestNode.create(%{jabba: "dabba"})
    assert Util.to_json(source) == "{\"jabba\":\"dabba\",\"id\":\"#{source[:id]}\"}"
  end
  
  test "domain document to json" do
    source = UtilTestDoc.create(%{jabba: "dabba"})
    assert Util.to_json(source) == "{\"jabba\":\"dabba\",\"id\":\"#{source[:id]}\"}"
  end
  
  test "vertex to json" do
    source = UtilTestNode.create(%{jabba: "dabba"})
    assert Util.to_json(source.vertex) == "{\"jabba\":\"dabba\",\"id\":\"#{source[:id]}\"}"
  end
  
  test "map to javascript" do
    map = %{foo: "bar", jabba: 12}
    assert Util.to_javascript(map) == "{foo: \"bar\", jabba: 12}"
  end

end

defmodule UtilTestGraph do
  use Xarango.Domain.Graph
end

defmodule UtilTestNode do
  use Xarango.Domain.Node, graph: UtilTestGraph
end

defmodule UtilTestDoc do
  use Xarango.Domain.Document
end

