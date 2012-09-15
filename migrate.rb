require 'rubygems'
require 'redis'

r = Redis.new

l = r.mget "*"
a = r.keys "*"
b = a.zip l
puts l,a,b

b.each {|s| 
  r.set "attendance:"+s[0], s[1]
  r.del s[0]
}
