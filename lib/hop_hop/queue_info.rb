module HopHop
  class QueueInfo
    attr_reader :message_count, :consumer_count

    def initialize(message_count, consumer_count)
      @consumer_count=consumer_count
      @message_count=message_count
    end
  end
end
