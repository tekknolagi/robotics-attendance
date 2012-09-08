require 'rubygems'
require 'sinatra'
require 'date'

# to list all students:
# $redis.mget(r.keys 'student*')

# to list all checkins for 9/7 (M/D)
# $redis.mget(r.keys 'signin:9:7*')

configure do
  enable :sessions
  set :environment, :development

  $password = "machine8"
  $backend = "redis"

  if $backend == "sqlite"
    require 'sqlite3'
    $db_name = "attendance.db"
    unless File.exists? $db_name
      $db = SQLite3::Database.new($db_name)
      $db.execute("create table student (id int, name text)")
      $db.execute("create table signin  (time int, date text, id int)")
    else
      $db = SQLite3::Database.new($db_name)
    end
  else
    require 'redis'
    $redis = Redis.new
    $password = $redis.get "password"
  end
end

def insert_student(id, name)
  if $backend == "sqlite"
    $db.execute("insert into student values ( ? , ? )", id, name)
  else
    $redis.set "student:#{id}", name
  end
end

def checkin_student(id)
  if $backend == "sqlite"
    $db.execute("insert into signin values ( ? , ? , ? )", DateTime.now.to_time.to_i.to_s, "#{DateTime.now.month}/#{DateTime.now.day}", id)
  else
    $redis.set "signin:#{DateTime.now.month}:#{DateTime.now.day}:#{id}", $redis.get("student:#{id}")
  end
end

def list_students(month, day)
  if $backend == "sqlite"
    return $db.execute("select student.name from signin inner join student on signin.id=student.id where signin.date = '#{month}/#{day}' order by time").flatten.uniq
  else
    Redis.current.quit
    $redis = Redis.new
    signins = $redis.keys "signin:#{month}:#{day}:*"
    if signins != []
      return $redis.mget(signins)
    else
      return []
    end
  end
end

def signed_in?
  return session[:user] == $password
end

def do_auth
  unless signed_in?
    session[:where] = request.path_info
    redirect '/login'
  end
end

def known_student?(id)
  if $backend == "sqlite"
    return $db.execute("select name from student where id = ?", id).flatten.uniq != []
  else
    Redis.current.quit
    $redis = Redis.new
    return $redis.get("student:#{id}") != nil
  end
end

get '/' do
  do_auth
  erb :index
end

get '/login' do
  erb :login
end

post '/login' do
  session[:user] = params["pass"]
  redirect session[:where] || "/"
end

get '/logout' do
  session[:user] = "invalid"
  erb :logout
end

get '/add' do
  do_auth
  erb :add
end

post '/add' do
  do_auth
  unless known_student? session[:id]
    insert_student(session[:id], params["name"])
    checkin_student(session[:id])
  end
  redirect '/'
end

post '/' do
  do_auth
  if known_student? params["id"]
    checkin_student(params["id"])
  else
    session[:id] = params["id"]
    redirect '/add'
  end
  erb :index
end

get '/today' do
  do_auth
  @people = list_students(DateTime.now.month, DateTime.now.day)
  erb :display
end

get '/:month/:day' do
  do_auth
  @people = list_students(params[:month], params[:day])
  erb :display
end
