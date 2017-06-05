defmodule TaskTest do
  use ExUnit.Case
  doctest Xarango
  import Xarango.TestHelper

  alias Xarango.Task

  # setup do
  #   on_exit fn ->
  #     Collection.__destroy_all
  #   end
  # end

  test "list tasks" do
    tasks = Task.tasks
    assert is_list(tasks)
    assert length(tasks) > 0
  end

  test "get task" do
    tasks = Task.tasks
    task = Task.task(Enum.at(tasks, 0))
    assert task.__struct__ == Task
  end

  test "create task" do
    source = _task()
    task = Task.create(source)
    Task.destroy(task)
    assert task.name == source.name
    refute is_nil(task.id)
  end

  test "create task with id" do
    id = name_()
    source = %Task{ _task() | id: id }
    task = Task.create(source)
    Task.destroy(task)
    assert task.name == source.name
    assert task.id == id
  end

  test "destroy task" do
    task = Task.create(_task())
    result = Task.destroy(task)
    refute result[:error]
  end

  defp _task do
    %Task{name: name_(), command: "(function(params){return params})(params)", params: %{foo: "bar"}, period: 3}
  end


end
