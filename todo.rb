require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

before '/lists/:list_id*' do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
end

before '/lists/:list_id/:tasks/:task_id' do
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
  session[:lists].delete_at(@list_id)
  session[:success] = 'The list was successfully deleted.'
  redirect '/lists'
end

# Add a task to an existing list
post '/lists/:list_id/task' do
  task_name = params[:task].strip
  error = error_for_task_name(task_name, @list_id)
  if error
    session[:error] = error
    erb :single_list, layout: :layout
  else
    @list[:todos] << { name: task_name, completed: false }
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
    session[:lists][@list_id][:name] = new_list_name
    session[:success] = 'The name of the list was sucessfully changed.'
    redirect "/lists/#{@list_id}"
  end
end

# Update completed status of an existing task
post '/lists/:list_id/tasks/:task_id' do
  task = session[:lists][@list_id][:todos][@task_id]
  params[:completed] == "true" ? task[:completed] = true : task[:completed] = false
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
post '/lists/:list_id/delete_task/:task_id' do
  @list = session[:lists][@list_id]
  @list[:todos].delete_at(@task_id)
  session[:success] = "The task has been deleted."
  redirect "/lists/#{@list_id}"
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
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
def error_for_task_name(name, list_number)
  if !(1..100).cover?(name.size)
    'The task name must be between 1 and 100 characters.'
  end
end

def load_list(list_id)
  if session[:lists][list_id]
    list = session[:lists][list_id]
    return list
  else
    session[:error] = 'The specified list was not found.'
    redirect '/'
  end
end

helpers do
  def list_complete?(list)
    tasks_count(list) > 0 && incomplete_tasks_count(list) == 0
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

  def sorted_lists(lists, &block)
    complete, incomplete = lists.partition { |list| list_complete?(list) }
    incomplete.each { |list| yield(list, lists.find_index(list)) }
    complete.each { |list| yield(list, lists.find_index(list)) }
  end

  def sorted_tasks(tasks, &block)
    complete, incomplete = tasks.partition { |task| task[:completed] }
    incomplete.each { |task| yield(task, tasks.find_index(task)) }
    complete.each { |task| yield(task, tasks.find_index(task)) }
  end
end
