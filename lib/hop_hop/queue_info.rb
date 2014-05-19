module HopHop
  # this is the info that is returned to the consumer on every event, it gives
  # a small interface to the queue

  class QueueInfo
    def initialize(queue_connection)
      @queue_connection = queue_connection
    end

    def message_count
      @queue_connection.queue.message_count
    end
  end
end
