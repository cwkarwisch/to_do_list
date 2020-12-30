class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
  end

  def all_lists
    @session[:lists]
  end

  def delete_list(list_id)
    @session[:lists].delete_if { |list| list[:id] == list_id }
  end

  def delete_task(list_id, task_id)
    list = find_list(list_id)
    list[:todos].delete_if { |task| task[:id] == task_id }
  end

  def rename_list(list_id, new_list_name)
    @session[:lists].find { |list| list[:id] == list_id }[:name] = new_list_name
  end

  def add_list(list_name)
    id = next_element_id(@session[:lists])
    @session[:lists] << { name: list_name, todos: [], id: id }
  end

  def add_task(list_id, task_name)
    list = @session[:lists].find { |list| list[:id] == list_id }
    id = next_element_id(list[:todos])
    list[:todos] << { name: task_name, completed: false, id: id }
  end

  def list_exists?(name)
    @session[:lists].any? { |list| list[:name] == name }
  end

  def find_list(list_id)
    @session[:lists].find { |list| list[:id] == list_id }
  end

  def find_task(list_id, task_id)
    @session[:lists].find { |list| list[:id] == list_id }[:todos].find { |task| task[:id] == task_id }
  end

  def toggle_task_completion_status(task, new_status)
    task[:completed] = new_status
  end

  def mark_all_tasks_complete(list_id)
    list = find_list(list_id)
    list[:todos].each do |task|
      task[:completed] = true
    end
  end

  private

  def next_element_id(collection)
    max = collection.map { |element| element[:id] }.max || 0
    max + 1
  end
end