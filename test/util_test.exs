defmodule UtilTest do
  use ExUnit.Case

  alias Xarango.Util

  setup do
    on_exit fn ->
      Xarango.Graph.__destroy_all()
      Xarango.Collection.__destroy_all()
    end
  end

  test "domain node to resource" do
    source = UtilTestNode.create(%{jabba: "dabba"})
    assert Util.to_resource(source) == %{id: source[:id], jabba: "dabba"}
  end

  test "domain node to resource with encoded ID" do
    source = UtilTestNode.create(%{jabba: "dabba"})
    assert Util.to_resource(source, encode_id: true) == %{id: URI.encode_www_form(source[:id]), jabba: "dabba"}
  end

  test "domain node to resource with relationships" do
    author = UtilTestAuthor.create(%{name: "Author"})
    1..3 |> Enum.each(fn idx ->
      book = UtilTestBook.create(%{title: "Book #{idx}"})
      UtilTestGraph.add(book, :written_by, author)
      1..3 |> Enum.each(fn idx ->
        chapter = UtilTestChapter.create(%{title: "Chapter #{idx}"})
        UtilTestGraph.add(chapter, :part_of, book)
      end)
    end)
    resource = Util.to_resource(author)
    id = author[:id]
    assert %{id: ^id, name: "Author"} = resource
    assert length(resource[:written_by]) == 3
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

defmodule UtilTestNode do
  use Xarango.Domain.Node, graph: UtilTestGraph
end

defmodule UtilTestBook do
  use Xarango.Domain.Node, graph: UtilTestGraph
end

defmodule UtilTestAuthor do
  use Xarango.Domain.Node, graph: UtilTestGraph
end

defmodule UtilTestChapter, do: use Xarango.Domain.Node, graph: UtilTestGraph

defmodule UtilTestGraph do
  use Xarango.Domain.Graph

  relationship UtilTestBook, :written_by, UtilTestAuthor
  relationship UtilTestChapter, :part_of, UtilTestBook
end



defmodule UtilTestDoc do
  use Xarango.Domain.Document
end

