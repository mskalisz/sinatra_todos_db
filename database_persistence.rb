require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: "todos")
    end
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(id)
    sql = <<~SQL
    SELECT lists.*, 
      COUNT(todos.id) AS todos_count,
      COUNT(NULLIF(todos.completed, false)) AS todos_remaining_count
      FROM lists
      LEFT JOIN todos ON todos.list_id = lists.id
      WHERE lists.id = $1
      GROUP BY lists.id
      ORDER BY lists.name;
  SQL
    result = query(sql, id)

    tuple = result.first

    { id: tuple["id"].to_i,
      name: tuple["name"], 
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i }
  end

  def all_lists
    sql = <<~SQL
      SELECT lists.*, 
        COUNT(todos.id) AS todos_count,
        COUNT(NULLIF(todos.completed, false)) AS todos_remaining_count
        FROM lists
        LEFT JOIN todos ON todos.list_id = lists.id
        GROUP BY lists.id
        ORDER BY lists.name;
    SQL
    result = query(sql)
    
    result.map do |tuple|
      { id: tuple["id"].to_i,
        name: tuple["name"], 
        todos_count: tuple["todos_count"].to_i,
        todos_remaining_count: tuple["todos_remaining_count"].to_i }
    end
  end

  def create_new_list(list_name)
    sql = "INSERT INTO lists (name) VALUES ($1);"
    result = query(sql, list_name)
  end

  def delete_list(id)
    query("DELETE FROM todos WHERE list_id = ($1);", id)
    query("DELETE FROM lists WHERE id = ($1);", id)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $2 WHERE id = $1;"
    query(sql, id, new_name) 
  end

  def create_new_todo(list_id, todo_name)
    sql = "INSERT INTO todos (name, list_id) VALUES ($1, $2);"
    result = query(sql, todo_name, list_id)
  end

  def delete_todo_from_list(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2;"
    query(sql, todo_id, list_id)
  end

  def update_todo_status(list_id, todo_id, new_status)
    sql = "UPDATE todos SET completed = $3 WHERE id = $1 AND list_id = $2;"
    query(sql, todo_id, list_id, new_status)
  end

  def mark_all_todos_as_completed(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1;"
    query(sql, list_id)
  end

  def disconnect
    @db.close
  end
  
  def find_todos(list_id)
    todo_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todo_sql, list_id)

    todos = todos_result.map do |todo_tuple|
      { id: todo_tuple["id"].to_i, 
        name: todo_tuple["name"], 
        completed: todo_tuple["completed"] == "t" }
    end
  end
end