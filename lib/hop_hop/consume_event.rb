module HopHop
  # This class abstracts the rabbitmq informations that it get from the subscribe loop and holds only
  # the information we allow (data and meta)

  class ConsumeEvent
    # @param data Hash is the data that you sent
    # @param meta Hash of the meta data that was sent, this object will give you some readers to it
    # @param context Object something the receiver can set to have a reference for later
    def initialize(data, meta, context = nil)
      @data = data
      @meta = meta
      @context = context
    end

    attr_reader :meta, :data, :context

    # @return [Time] when the message was sent
    def sent_at
      @sent_at ||= Time.at(meta[:timestamp])
    end

    # @return [String] the name of the event (=routing key)
    def name
      meta[:routing_key]
    end

    # @return [String] the producer in the format of host.pid.subsystem e.g. "www.experteer.de.9989.career"
    def producer
      @producer ||= meta[:headers][:producer]
    end

    # @return [Integer] the version of the message
    def version
      @version ||= meta[:headers][:version]
    end
  end
end
