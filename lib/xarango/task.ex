defmodule Xarango.Task do
  
  defstruct [:id, :name, :type, :period, :created, :command, :database, :params, :offset]
  
  alias Xarango.Task
  alias Xarango.Client
  
  def tasks do
    url("")
    |> Client.get
    |> Enum.map(&to_task(&1))
  end
  
  def task(task) do
    url(task.id)
    |> Client.get
    |> to_task
  end
  
  def create(%Task{id: id} = task) when not is_nil(id) do
    url(task.id)
    |> Client.put(Map.take(task, [:params, :offset, :command, :name, :period]))
  end

  def create(task) do
    url("")
    |> Client.post(Map.take(task, [:params, :offset, :command, :name, :period]))
  end
  
  def destroy(task) do
    url(task.id)
    |> Client.delete
  end

  defp to_task(data) do
    struct(Task, data)
  end
  
  defp url(path, options\\[]) do
    Xarango.Connection.url("/_api/tasks/#{path}", options)
  end
  
end