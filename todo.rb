require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View all lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# View an individual list
get '/lists/:number' do
  index = params[:number].to_i
  @list = session[:lists][index]
  erb :single_list, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
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
    session[:success] = 'The list was sucessfully created'
    redirect '/lists'
  end
end

# Returns an error message if name is invalid. Returns nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'The list name must be between 1 and 100 characters'
  elsif session[:lists].any? { |list| list[:name] == name }
    'The list name must be unique'
  end
end
