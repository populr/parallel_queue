class ParallelQueue

  def initialize(redis, queue_name, options = {})
    @redis = redis
    @queue_name = queue_name
    @maxlength = options[:maxlength] || nil
    @lock_name = 'lock.' + @queue_name
    @current_queue_index = 0
  end


  def delete_queue(id)
    @redis.lrem(list_of_queue_names, 1, id)
    @redis.del(queue_from_id(id))
  end

  def empty?
    queue_count == 0
  end

  def queue_count
    @redis.llen(list_of_queue_names)
  end

  # <tt>:item</tt>:: A string
  #
  def enqueue(id, item)
    queue = queue_from_id(id)
    @redis.rpush(queue, item)
    @redis.ltrim(queue, -@maxlength, - 1) if @maxlength
    @redis.lrem(list_of_queue_names, 1, id)
    @redis.rpush(list_of_queue_names, id)
  end

  def dequeue
    if acquire_lock || break_lock
      current_id = @redis.lindex(list_of_queue_names, current_queue_index)

      # pop from the current queue
      current_queue = queue_from_id(current_id)
      item = @redis.lpop(current_queue)
      delete_queue(current_id) if @redis.llen(current_queue) == 0

      increment_current_queue_index
      release_lock
      item
    else # couldn't acquire or break the lock. wait and try again
      sleep 0.01
      dequeue
    end
  end

  def dequeue_each(&block)
    return if queue_count == 0
    self.current_queue_index = 0

    begin
      item = dequeue
      yield(item)
    end while current_queue_index > 0 && current_queue_index < queue_count
  end

  def delete_all!
    if acquire_lock || break_lock
      while !empty?
        delete_queue(@redis.lpop(list_of_queue_names))
      end
      @redis.del(list_of_queue_names)
      self.current_queue_index = 0
      release_lock
    else # couldn't acquire or break the lock. wait and try again
      sleep 0.01
      delete_all!
    end
  end


  def acquire_lock # :nodoc:
    @redis.setnx(@lock_name, new_lock_expiration)
  end

  def release_lock # :nodoc:
    @redis.del(@lock_name)
  end

  def break_lock # :nodoc:
    previous = @redis.getset(@lock_name, new_lock_expiration)
    previous.nil? || Time.at(previous.to_i) <= Time.now
  end

  protected

  def increment_current_queue_index
    self.current_queue_index = current_queue_index + 1
  end

  def current_queue_index # :nodoc:
    return 0 if queue_count == 0
    @current_queue_index % queue_count
  end

  def current_queue_index=(index) # :nodoc:
    @current_queue_index = index
  end


  private

  def list_of_queue_names
    "#{@queue_name}_qs"
  end

  def queue_from_id(id)
    "#{@queue_name}_q_#{id}"
  end


  LOCK_DURATION = 1

  def new_lock_expiration
    (Time.now + LOCK_DURATION).to_i
  end

end
