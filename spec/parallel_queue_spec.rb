require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ParallelQueue" do
  before(:each) do
    @redis = Redis.new(:host => '127.0.0.1', :port => '6379')
    @redis.del("demo_queue_current_q")
    @redis.del("demo_queue_qs")
    @redis.del("demo_queue_q_abc")
    @redis.del("demo_queue_q_peanuts")
    @redis.del("demo_queue_q_123")
    @queue = ParallelQueue.new(@redis, 'demo_queue')
  end

  after(:each) do
    @queue.delete_all!
  end

  describe "clear" do
    it "should" do
    end
  end

  describe "#enqueue" do
    context "when the specified id does not yet have a queue" do
      it "should create a new queue" do
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.queue_count.should == 1

        @queue.enqueue('123', 'hello world')
        @queue.queue_count.should == 2
      end
    end

    context "when the specified id already has a queue" do
      it "should not create a new queue" do
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.enqueue('peanuts', 'Charlie Brown')
        @queue.queue_count.should == 1
      end
    end

    context "when a maxlength is present, and that max is exceeded" do
      it "should discard the oldest item" do
        @queue = ParallelQueue.new(@redis, 'demo_queue', :maxlength => 3)
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.enqueue('peanuts', 'Woodstock')
        @queue.enqueue('peanuts', 'Charlie Brown')
        @queue.enqueue('peanuts', 'Lucy')

        results = []
        while !@queue.empty?
          results << @queue.dequeue
        end

        results.should include('Woodstock')
        results.should include('Charlie Brown')
        results.should include('Lucy')
        results.should_not include('Snoopy')
      end
    end
  end

  describe "#dequeue" do
    it "sequential dequeues should iterate through and dequeue from the current queues" do
      @queue.enqueue('peanuts', 'Snoopy')
      @queue.enqueue('peanuts', 'Charlie Brown')
      @queue.enqueue('123', 'hello')
      @queue.enqueue('123', 'world')
      results = []
      results << @queue.dequeue
      results << @queue.dequeue
      results.should include('Snoopy')
      results.should include('hello')
    end

    context "when the queue from which the item was removed not empty" do
      it "should not delete the empty queue" do
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.enqueue('peanuts', 'Charlie Brown')
        @queue.enqueue('123', 'hello')
        @queue.enqueue('123', 'world')

        @queue.dequeue
        @queue.queue_count.should == 2
        @queue.dequeue
        @queue.queue_count.should == 2
      end
    end

    context "when the queue from which the item was removed is empty" do
      it "should delete the empty queue" do
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.enqueue('123', 'hello world')

        @queue.dequeue
        @queue.queue_count.should == 1
        @queue.dequeue
        @queue.queue_count.should == 0
      end
    end
  end

  describe "#dequeue_each" do
    it "should call dequeue on every queue, passing the response to a block" do
      @queue.enqueue('peanuts', 'Snoopy')
      @queue.enqueue('peanuts', 'Charlie Brown')
      @queue.enqueue('123', 'hello')

      results = []
      @queue.dequeue_each do |item|
        results << item
      end
      results.should have(2).items
      results.should include('Snoopy')
      results.should include('hello')

      results = []
      @queue.dequeue_each do |item|
        results << item
      end
      results.should eq(['Charlie Brown'])
    end
  end


  describe "#delete_queue" do
    it "should delete an entire queue, even if it is not empty" do
      @queue.enqueue('123', 'hello world')
      @queue.should_not be_empty
      @queue.delete_queue('123')
      @queue.should be_empty
    end
  end

  describe "#delete_all!" do
    it "should remove all queues" do
      @queue.enqueue('123', 'hello world')
      @queue.enqueue('peanuts', 'Snoopy')
      @queue.should_not be_empty
      @queue.delete_all!
      @queue.should be_empty
    end
  end

  describe "#acquire_lock" do
    after(:each) do
      @queue.release_lock
    end

    context "when the lock is not already taken" do
      it "should return true" do
        @queue.acquire_lock.should be_true
      end

      it "should lock the resource" do
        @queue.acquire_lock
        @queue.acquire_lock.should be_false
      end
    end

    context "when the lock is already taken" do
      it "should return false" do
        @queue.acquire_lock
        @queue.acquire_lock.should be_false
      end
    end
  end

  describe "#break_lock" do
    after(:each) do
      @queue.release_lock
    end

    context "when the lock is not already taken" do
      it "should be true" do
        @queue.break_lock.should be_true
      end

      it "should lock the resource" do
        @queue.break_lock
        @queue.acquire_lock.should be_false
      end
    end

    context "when the lock is taken and not yet expired" do
      it "should be false" do
        @queue.acquire_lock
        @queue.break_lock.should be_false
      end
    end

    context "when the lock is taken, but expired" do
      it "should be true" do
        @queue.acquire_lock
        sleep(3)
        @queue.break_lock.should be_true
      end

      it "should lock the resource" do
        @queue.acquire_lock
        sleep(3)
        @queue.break_lock
        @queue.acquire_lock.should be_false
      end
    end

    it "should be able to break an expired lock acquired through breaking a lock" do
      @queue.break_lock
      sleep(3)
      @queue.break_lock.should be_true
    end
  end

  describe "#queue_count" do
    context "when the queue is empty" do
      it "should be 0" do
        @queue.queue_count.should == 0
      end
    end

    context "when the queue has N elements, regardless of whether or not they are ready to be dequeued" do
      it "should match the number of elements" do
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.queue_count.should == 1

        @queue.enqueue('123', 'hello')
        @queue.queue_count.should == 2

        @queue.enqueue('abc', 'a')
        @queue.queue_count.should == 3
      end
    end
  end

  describe "#empty?" do
    context "when the queue is empty" do
      it "should be true" do
        @queue.should be_empty
      end
    end

    context "when the queue has an element that is not ready to be dequeued" do
      it "should be false" do
        @queue.enqueue('peanuts', 'Snoopy')
        @queue.should_not be_empty
      end
    end
  end
end
