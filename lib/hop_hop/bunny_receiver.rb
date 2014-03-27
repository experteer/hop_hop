module HopHop
  #this class will bind to the events exchange, create the queue, receive messages from the queue, wrap them into HopHop::CustomEvent
  #and dispatch it to a HohHop::Cunsumer instance.
  class BunnyReceiver

    #@param [Hash] options
    #@option options [String] :host the hostname of the rabbit mq server (localhost)
    #@option options [Integer] :port the port the rabbit mq server (5672)
    #@option options [String] :exchange name of the exchange to bind to (events)
    #@option options [Logger] :logger a logger to log cosnume errors (Logger.new(STDOUT))
    def initialize(options={:host => 'localhost', :port => 5672, :exchange => 'events'})
      @options=options
      @exchange_name=options[:events] || 'events'
      @logger = options[:logger] || Logger.new(STDOUT)
    end

    #This will start the blocking loop to fetch messagesfrom the queue.
    #Ack are send if no exceptions are thrown. On exceptions the ack is NOT sent!
    #@param [HopHop::Consumer] consumer the consumer that will get the callback
    def consume(consumer)
      @consumer=consumer
      bind

      begin
        queue.subscribe(:block => true, :ack => true) do |delivery_info, properties, body|
          meta={
            :routing_key => delivery_info.routing_key,
            :timestamp => properties.timestamp,
            :headers => {
              :producer => properties.headers["producer"],
              :version => properties.headers["version"]
            }
          }
          event=HopHop::ConsumeEvent.new(JSON.parse(body), meta)
          begin
            consumer.consume(event)
            channel.ack(delivery_info.delivery_tag)
          rescue Object => err #I really catch everything, even Timeout (not inherited from Exception)
            raise if err.kind_of?(Interrupt) #but Interrupts should still work
            logger.error("Consumer failed: #{err.message}\n#{err.backtrace.join("\n")}\n#{event.inspect}")
          end
        end
      rescue Interrupt => _ #perhaps ensure is better here
        channel.close
        connection.close
      end
    end

    private
    attr_reader :consumer, :logger, :options

    #this will bind to the exchange. As a sideffect it will establish the connection and create the queue
    def bind
      consumer.class.bind.each do |event_pattern|
        queue.bind(exchange, :routing_key => event_pattern)
      end
      nil
    end

    #@note: don't call this before consumer is set
    def queue
      @queue||=channel.queue(consumer.class.queue, :durable => true)
    end

    def exchange
      @exchange||channel.topic(@exchange_name, :durable => true)
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      return @connection if defined?(@connection)
      @connection = Bunny.new(:host => @options[:host], :port => @options[:port])
      @connection.start
      @connection
    end
  end
end