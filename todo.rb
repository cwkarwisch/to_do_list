require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

DIGITS = '([0-9]+)'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

before /\/lists\/#{DIGITS}/ do
  @list_id = params['captures'].first.to_i
  @list = load_list(@list_id)
end

before '/lists/:list_id/:tasks/:task_id*' do
  @task_id = params[:task_id].to_i
end

get '/' do
  redirect '/lists'
end

# View all lists
get '/lists' do
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# View an individual list
get '/lists/:list_id' do
  erb :single_list, layout: :layout
end

# Edit an individual list
get '/lists/:list_id/edit' do
  erb :edit_list, layout: :layout
end

# Delete an individual list
post '/lists/:list_id/delete' do
  session[:lists].delete_if { |list| list[:id] == @list_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = 'The list was successfully deleted.'
    redirect '/lists'
  end
end

# Add a task to an existing list
post '/lists/:list_id/task' do
  task_name = params[:task].strip
  error = error_for_task_name(task_name)
  if error
    session[:error] = error
    erb :single_list, layout: :layout
  else
    id = next_task_id(@list)
    @list[:todos] << { name: task_name, completed: false, id: id }
    session[:success] = 'The task was successfully added.'
    redirect "/lists/#{@list_id}"
  end
end

# Edit the name of an existing list
post '/lists/:list_id' do
  new_list_name = params[:new_list_name].strip
  error = error_for_list_name(new_list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists].find { |list| list[:id] == @list_id }[:name] = new_list_name
    session[:success] = 'The name of the list was sucessfully changed.'
    redirect "/lists/#{@list_id}"
  end
end

# Update completed status of an existing task
post '/lists/:list_id/tasks/:task_id' do
  task = load_task(@list_id, @task_id)
  task[:completed] = params[:completed] == "true" ? true : false
  redirect "/lists/#{@list_id}"
end

# Mark all tasks in a list as complete
post '/lists/:list_id/complete_all' do
  @list[:todos].each do |task|
    task[:completed] = true
  end
  redirect "/lists/#{@list_id}"
end

# Delete a task from an existing list
post '/lists/:list_id/tasks/:task_id/delete' do
  @list[:todos].delete_if { |task| task[:id] == @task_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The task has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    id = next_list_id
    session[:lists] << { name: list_name, todos: [], id: id }
    session[:success] = 'The list was sucessfully created.'
    redirect '/lists'
  end
end

# Returns an error message if list name is invalid. Returns nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'The list name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'The list name must be unique.'
  end
end

# Returns an error message if task name is invalid. Returns nil if name valid.
def error_for_task_name(name)
  if !(1..100).cover?(name.size)
    'The task name must be between 1 and 100 characters.'
  end
end

def load_list(list_id)
  list = session[:lists].find { |list| list[:id] == list_id }
  if list
    return list
  else
    session[:error] = 'The specified list was not found.'
    redirect '/'
  end
end

def load_task(list_id, task_id)
  task = session[:lists].find { |list| list[:id] == list_id }[:todos].find { |task| task[:id] == task_id }
  if task
    return task
  else
    session[:error] = 'The specified task was not found.'
    redirect "/lists/#{list_id}"
  end
end

def next_list_id
  max = session[:lists].map { |list| list[:id] }.max || 0
  max + 1
end

def next_task_id(list)
  max = list[:todos].map { |task| task[:id] }.max || 0
  max + 1
end

helpers do
  def list_complete?(list)
    tasks_count(list) > 0 && incomplete_tasks_count(list) == 0
  end

  def task_complete?(task)
    task[:completed] == true
  end

  def incomplete_tasks_count(list)
    list[:todos].count { |task| task[:completed] == false }
  end

  def tasks_count(list)
    list[:todos].size
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def task_class(task)
    "complete" if task_complete?(task)
  end

  def sorted_lists(lists, &block)
    complete, incomplete = lists.partition { |list| list_complete?(list) }
    incomplete.each { |list| yield(list) }
    complete.each { |list| yield(list) }
  end

  def sorted_tasks(tasks, &block)
    complete, incomplete = tasks.partition { |task| task[:completed] }
    incomplete.each { |task| yield(task, task[:id]) }
    complete.each { |task| yield(task, task[:id]) }
  end
end
