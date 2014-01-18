class Task
  attr_accessor :status, :description, :priority, :tags

  def initialize(status, description, priority, tags=nil)
    @status = status.downcase.to_sym
    @description = description
    @priority = priority.downcase.to_sym
    @tags = tags.to_s.split(',').map &:strip
  end
end

class Criteria
  attr_reader :lambda

  def initialize(lambda)
    @lambda = lambda
  end

  def Criteria.status(target_status)
    new -> todo { todo.status == target_status }
  end

  def Criteria.priority(target_priority)
    new -> todo { todo.priority == target_priority }
  end

  def Criteria.tags(target_tags)
    new -> todo { target_tags.size == (todo.tags & target_tags).size }
  end

  def &(other)
    Criteria.new -> todo { @lambda.call(todo) and other.lambda.call(todo) }
  end

  def |(other)
    Criteria.new -> todo { @lambda.call(todo) or other.lambda.call(todo) }
  end

  def !
    Criteria.new -> todo { not @lambda.call(todo) }
  end
end

class TodoList
  include Enumerable
  attr_accessor :task_list

  def initialize(list)
    @task_list = list
  end

  def TodoList.parse(text)
    new text.split("\n").map { |row| Task.new(*row.split("|").map(&:strip)) }
  end

  def each
    @task_list.each { |task| yield task}
  end

  def filter(criteria)
    TodoList.new @task_list.select(&criteria.lambda).compact
  end

  def adjoin(other)
    TodoList.new @task_list | other.task_list
  end

  def tasks_todo
    @task_list.count { |task| task.status == :todo }
  end

  def tasks_in_progress
    @task_list.count { |task| task.status == :current }
  end

  def tasks_completed
    @task_list.count { |task| task.status == :done }
  end

  def completed?
    @task_list.map { |task| task.status == :done }.all?
  end
end