require 'pg'

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: "todos")
          end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def all_lists
    sql = 'SELECT * FROM lists'
    result = query(sql)
    result.map do |tuple|
      tasks = all_tasks(tuple)
      { id: tuple['id'].to_i, name: tuple['name'], todos: tasks }
    end
  end

  def find_list(list_id)
    sql = 'SELECT * FROM lists WHERE id = $1'
    result = query(sql, list_id)
    tuple = result.first
    tasks = all_tasks(tuple)
    {id: tuple['id'].to_i, name: tuple['name'], todos: tasks }
  end

  def add_list(list_name)
    sql = 'INSERT INTO lists (name) VALUES ($1);'
    query(sql, list_name)
  end

  def rename_list(list_id, new_list_name)
    sql = 'UPDATE lists SET name = $1 WHERE id = $2'
    query(sql, new_list_name, list_id)
  end

  def delete_list(list_id)
    query('DELETE FROM tasks WHERE list_id = $1;', list_id)
    query('DELETE FROM lists WHERE id = $1;', list_id)
  end

  def find_task(task_id)
    sql = 'SELECT * FROM tasks WHERE id = $1'
    result = query(sql, task_id)
    tuple = result.first
    completed_status = tuple['completed'] == 't' ? true : false
    { id: tuple['id'].to_i,
    name: tuple['name'],
    completed: completed_status }
  end

  def add_task(list_id, task_name)
    sql = 'INSERT INTO tasks (name, list_id) VALUES ($1, $2);'
    query(sql, task_name, list_id)
  end

  def toggle_task_completion_status(list_id, task_id, new_status)
    sql = 'UPDATE tasks SET completed = $1 WHERE list_id = $2 AND id = $3'
    query(sql, new_status, list_id, task_id)
  end

  def mark_all_tasks_complete(list_id)
    sql = 'UPDATE tasks SET completed = true WHERE list_id = $1'
    query(sql, list_id)
  end

  def delete_task(list_id, task_id)
    sql = 'DELETE FROM tasks WHERE list_id = $1 AND id = $2'
    query(sql, list_id, task_id)
  end

  private

  def all_tasks(list)
    list_id = list['id']
    task_sql = 'SELECT * FROM tasks WHERE list_id = $1'
    tasks = query(task_sql, list_id)

    tasks = tasks.map do |task_tuple|
      completed_status = task_tuple['completed'] == 't' ? true : false
      { id: task_tuple['id'].to_i,
        name: task_tuple['name'],
        completed: completed_status }
    end
  end
end