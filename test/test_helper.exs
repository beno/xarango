defmodule Xarango.TestHelper do

  def name_ do
    Faker.Lorem.word <> Faker.Lorem.word
  end
  
  def graph_ do
    # %Xarango.Graph{name: name_, edgeDefinitions: [%{collection: name_, from: ["start"], to: ["end"]}]}
    %Xarango.Graph{name: name_}
  end
  
  def document_ do
    %Xarango.Document{_data: %{field: name_}}
  end

  def vertex_ do
    %Xarango.Vertex{_data: %{field: name_}}
  end
  
  def vertex_collection_ do
    %Xarango.VertexCollection{collection: name_}
  end
  
  def edge_collection_ do
    %Xarango.EdgeCollection{collection: name_}
  end
  
  def collection_ do
    %Xarango.Collection{name: name_}
  end

  def edge_ do
    %Xarango.Edge{_data: %{field: name_}}
  end

  def edge_def_ do
    %Xarango.EdgeDefinition{collection: name_, from: [name_], to: [name_]}
  end
  
  def user_ do
    %Xarango.User{user: name_, passw: name_}
  end
  
  def database_ do
    %Xarango.Database{name: name_}
  end

  
end

ExUnit.start()
