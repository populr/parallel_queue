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
    queue = ParallelQueue.new(redis, 'my_object_message_queue', :maxlength => 1000)
    # The optional :maxlength option limits the length of each individual message queue.
    # When a queue that already has maxlength messages receives a new message, the
    # oldest message in that queue is discarded (O(1)).
    # Because there is one queue per message emitter, one queue becoming full has no effect
    # on the remaining queues (no messages will be lost for other emitters unless they,
    # too, reach :maxlength). If maxlength is omitted, then queue length is not
    # artificially limited.
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



Testing in multiple threads
===========================

A couple files are provided to make it easy to test this in multiple threads. Start by opening three terminals (I use the [byobu](https://launchpad.net/byobu) flavor of [screen](http://www.gnu.org/software/screen/)) and cd-ing to the root of this project.

Terminal 1:

    $ ruby dequeue_demo.rb d1.txt

Terminal 2:

    $ ruby dequeue_demo.rb d2.txt

Terminal 3 (run the command in terminal 3 after starting 1 & 2):

    $ ruby enqueue_demo.rb
    This will automatically end after enqueueing 40000 times
    Terminals 1 & 2 will automatically stop when they finish processing
    the data enqueued by Terminal 3.

To check for any common values between d1.txt and d2.txt (there should be none):

    $ comm -1 -2 d1.txt d2.txt
    should not have any matches (make sure you delete
    the two files between runs)



Contributing to parallel_queue
==========================

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add specs for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
