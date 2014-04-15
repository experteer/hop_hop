module HopHop
  # this class will bind to the events exchange, create the queue, receive messages from the queue, wrap them into HopHop::CustomEvent
  # and dispatch it to a HohHop::Cunsumer instance.
  class BunnyReceiver
    # @param [Hash] options
    # @option options [String] :host the hostname of the rabbit mq server (localhost)
    # @option options [Integer] :port the port the rabbit mq server (5672)
    # @option options [String] :exchange name of the exchange to bind to (events)
    # @option options [Logger] :logger a logger to log cosnume errors (Logger.new(STDOUT))
    def initialize(options = { host: 'localhost', port: 5672 })
      @options = options
      @logger = options[:logger] || Logger.new(STDOUT)
    end

    # This will start the blocking loop to fetch messagesfrom the queue.
    # Ack are send if no exceptions are thrown. On exceptions the ack is NOT sent!
    # @param [HopHop::Consumer] consumer the consumer that will get the callback
    # @return [Boolean] true if loop was stopped with exit_loop, false if Interrupt was raised
    def consume(consumer)
      qc = connect(consumer)
      logger.debug "Consumer looping: #{consumer.name}"
      qc.loop # this runs the loop and only exists on Interrupts or #exit_loop
    end

    private
    attr_reader :options, :logger
    def connect(consumer)
      qc = QueueConnection.new(consumer,
                               Helper.slice_hash(options, :host, :port, :virtual_host))
      consumer.on_bind
      qc
    end
  end
end
