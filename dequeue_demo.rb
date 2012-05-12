$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'redis'
require 'parallel_queue'
require 'pry'
require 'pry-nav'
require 'pry-stack_explorer'

redis = Redis.new(:host => '127.0.0.1', :port => '6379')
queue = ParallelQueue.new(redis, 'demo_queue')

filename = ARGV[0]
return puts "File name required" if filename.nil?

array = []
start = nil
while array.empty? || queue.queue_count > 0
  start = Time.now if start.nil? && !array.empty?
  queue.dequeue_each() do |item|
    array << item.to_i
    puts "dequeue: #{item}"
  end
end
puts Time.now - start
File.open(filename, 'w') { |f| f.write(array.sort.join("\n")) }