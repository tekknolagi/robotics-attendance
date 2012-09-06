require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'date'

configure do
  enable :sessions
  $password = "machine8"

  $db_name = "attendance.db"
  unless File.exists? $db_name
    $db = SQLite3::Database.new($db_name)
    $db.execute("create table student (id int, name text)")
    $db.execute("create table signin  (time int, date text, id int)")
  else
    $db = SQLite3::Database.new($db_name)
  end
end

def insert_student(id, name)
  $db.execute("insert into student values ( ? , ? )", id, name)
end

def checkin_student(id)
  $db.execute("insert into signin values ( ? , ? , ? )", DateTime.now.to_time.to_i.to_s, "#{DateTime.now.month}/#{DateTime.now.day}", id)
end

def list_students(month, day)
  return $db.execute("select student.name from signin inner join student on signin.id=student.id where signin.date = '#{month}/#{day}' order by time").flatten.uniq
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

get '/' do
  do_auth
  erb :index
end

get '/login' do
  erb :login
end

post '/login' do
  session[:user] = params["pass"]
  redirect session[:where]
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
  insert_student(params["id"], params["name"])
  erb :add
end

post '/' do
  do_auth
  checkin_student(params["id"])
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
