module HopHop
  class QueueConnection
    def initialize(consumer, options={})
      @consumer=consumer
      @options=options
      @options[:prefetch] ||= 1
      @logger=options[:logger] || Logger.new(STDOUT)

      @exchange_name = options[:exchange] || 'events'
      bind #leave this here as on receiver.connect all bindings should be in place
    end

    #@return [Boolean] true if exit_loop was called and false if interrupted
    def loop
      begin
        stopping=false
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
          info=QueueInfo.new(self)

          begin
            begin
              logger.debug("Consuming: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
              consumer.consume(event, info)
            rescue HopHop::Consumer::ExitLoop
              stopping=true
            end

            logger.debug("Acknowledged: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
            channel.ack(delivery_info.delivery_tag)
          rescue Object => err #I really catch everything, even Timeout (not inherited from Exception)
            raise if err.kind_of?(Interrupt) #but Interrupts should still work
            logger.error("Consumer failed: #{consumer.name} #{err.message}\n#{err.backtrace.join("\n")}\n#{event.inspect}")
          end

          if stopping
            logger.info("Stopping: #{consumer.name}")
            delivery_info.consumer.cancel
          end

        end
      rescue Interrupt => _ #perhaps ensure is better here
        logger.info("Consumer #{consumer.name} terminated")
        channel.close
        connection.close
        raise #so you can stop your scripts
      end
      stopping
    end

    #this will bind to the exchange. As a sideffect it will establish the connection and create the queue
    def bind
      logger.debug "Binding: #{consumer.name} -> #{consumer.bindings.inspect}"
      consumer.bindings.each do |event_pattern|
        queue.bind(exchange, :routing_key => event_pattern)
      end
      nil
    end

    attr_reader :consumer, :logger, :options


    #@note: don't call this before consumer is set
    def queue

      options={:durable => true}
      options[:exclusive] = true if consumer.queue.nil? || consumer.queue.empty?
      @queue||=channel.queue(consumer.queue, options)
    end

    def exchange
      @exchange||=channel.topic(@exchange_name, :durable => true)
    end

    def channel
      return @channel if defined?(@channel)
      @channel = connection.create_channel
      @channel.prefetch(options[:prefetch])
      @channel
    end

    def connection
      return @connection if defined?(@connection)
      @connection = Bunny.new(:host => @options[:host], :port => @options[:port])
      @connection.start
      @connection
    end

  end

end