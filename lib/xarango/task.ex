defmodule Xarango.Task do
  
  defstruct [:id, :name, :type, :period, :created, :command, :database, :params, :offset]
  
  alias Xarango.Task
  import Xarango.Client
  use Xarango.URI, [prefix: "tasks"]
  
  def tasks do
    url("")
    |> get
    |> Enum.map(&to_task(&1))
  end
  
  def task(task) do
    url(task.id)
    |> get
    |> to_task
  end
  
  def create(%Task{id: id} = task) when not is_nil(id) do
    url(task.id)
    |> put(Map.take(task, [:params, :offset, :command, :name, :period]))
  end

  def create(task) do
    url("")
    |> post(Map.take(task, [:params, :offset, :command, :name, :period]))
  end
  
  def destroy(task) do
    url(task.id)
    |> delete
  end

  defp to_task(data) do
    struct(Task, data)
  end
    
end