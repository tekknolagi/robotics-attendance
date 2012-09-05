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

# seed values. need to populate db with names and IDs somehow.
=begin
    $db.execute("insert into student values (3, 'max')")
    $db.execute("insert into student values (4, 'jack')")
    $db.execute("insert into student values (5, 'matt')")
=end
  else
    $db = SQLite3::Database.new($db_name)
  end
end

get '/' do
  unless session[:user] == $password
    redirect '/login'
  end
  erb :index
end

get '/login' do
  erb :login
end

post '/login' do
  session[:user] = params["pass"]
  redirect '/'
end

get '/logout' do
  session[:user] = "invalid"
  erb :logout
end

post '/' do
  $db.execute("insert into signin values ( ? , ? , ? )", DateTime.now.to_time.to_i.to_s, "#{DateTime.now.month}/#{DateTime.now.day}", params["id"].to_i)
  erb :index
end

get '/today' do
  @people = $db.execute("select student.name from signin inner join student on signin.id=student.id where signin.date = '#{DateTime.now.month}/#{DateTime.now.day}' order by time").flatten.uniq
  erb :display
end

get '/:month/:day' do
  @people = $db.execute("select student.name from signin inner join student on signin.id=student.id where signin.date = '#{params[:month]}/#{params[:day]}' order by time").flatten.uniq
  erb :display
end
