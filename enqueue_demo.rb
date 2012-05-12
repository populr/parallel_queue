$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'redis'
require 'parallel_queue'
require 'pry'
require 'pry-nav'
require 'pry-stack_explorer'

redis = Redis.new(:host => '127.0.0.1', :port => '6379')
queue = ParallelQueue.new(redis, 'demo_queue', :maxlength => 1000)

counter = 0
ids = ['abc', 'def', 'ghi', 'jkl', 'mno', 'pqrs']
while counter < 40000
  id = ids.sample
  queue.enqueue(id, counter)
  puts "enqueue: #{counter}"
  counter += 1
end