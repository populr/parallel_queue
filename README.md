ParallelQueue
==========

ParallelQueue provides a thread safe, Redis backed, parallel queue abstraction. Motivation for creating this was for queueing messages based on ID so that very chatty message emitters don't prevent messages from others from being processed.



Usage
=====

In your Gemfile:

    gem 'parallel_queue'

Example:

    $ irb
    require 'redis'
    require 'parallel_queue'
    redis = Redis.new(:host => '127.0.0.1', :port => '6379')
    queue = ParallelQueue.new(redis, 'my_object_message_queue')
    queue.enqueue('123', 'hello world')
    queue.enqueue('peanuts', 'Chalie Brown')
    queue.enqueue('peanuts', 'Snoopy')

    puts queue.queue_count
      - 2

    queue.dequeue_each do |item|
      puts item
    end
      - 'hello world'
      - 'Charlie Brown'

    puts queue.queue_count
      - 1

    queue.dequeue_each  do |item|
      puts item
    end
      - 'Snoopy'

    puts queue.queue_count
      - 0

    queue.dequeue_each  do |item|
      puts item
    end

All items are queued and returned as strings.


Contributing to parallel_queue
==========================

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add specs for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
