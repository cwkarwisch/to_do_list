# To Do or Not To Do

To Do or Not To Do is a canonical to do list that provides an interactive web application for managing to do lists. The app originally persisted state in the user's session, but was refactored to connect to a PostgreSQL database.

A live demo is available at: https://cwk-todo-app.herokuapp.com/lists

# API

To Do or Not To Do provides an API to facilitate dynamic creation and deletion of to do lists and associated tasks. Routes are provided according to the following table:

| HTTP Method | Endpoint    | Description   |
| ----------- | ----------- | ------------- |
| GET         | /lists       | View all lists |
| POST         | /lists       | Create a new list |
| GET         | /lists/new       | Render the new list form |
| GET         | /lists/:list_id       | View an individual list |
| GET         | /lists/:list_id/edit       | Render the form to edit an individual list |
| POST         | /lists/:list_id/delete       | Delete an individual list |
| POST         | /lists/:list_id/task       | Add a task to an existing list |
| POST         | /lists/:list_id       | Edit the name of an existing list |
| POST         | /lists/:list_id/tasks/:task_id       | Update the completed status of an existing task |
| POST         | /lists/:list_id/complete_all       | Mark all tasks in a list as complete |
| POST         | lists/:list_id/tasks/:task_id/delete       | Delete a task from an existing list |


# Setup

If you'd like to run the application locally:

1. Clone the repository with `git clone https://github.com/cwkarwisch/to_do_list.git`
1. Install required gems with `bundle install`
1. Launch the application by running `ruby todo.rb`
1. View the application at ` http://localhost:4567`