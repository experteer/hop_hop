module HopHop
  # This can be used in a test environment to see whats pushed into the queue.
  class TestSender
    def initialize
      reset
    end

    def publish(data, options)
      @events << [data, options]
    end

    def reset
      @events = []
    end

    def size
      @events.size
    end

    def empty?
      @events.empty?
    end

    def [](num) # don't know how to delegate this
      @events[num]
    end
  end
end
