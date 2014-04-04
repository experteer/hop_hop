module HopHop
  class QueueConnection
    def initialize(consumer, options={})
      @consumer=consumer
      @options=options
      @options[:prefetch] ||= 1
      @options[:requeue_sleep] ||= 5
      @exchange_name = options[:exchange] || 'events'
      bind #leave this here as on receiver.connect all bindings should be in place
    end

    #@return [Boolean] true if exit_loop was called and false if interrupted
    def loop
      @stopping=false
      begin
        queue.subscribe(:block => true, :ack => true) do |delivery_info, properties, body|
          begin
            event=call_consumer(delivery_info, properties, body)
          rescue Object => err #I really catch everything, even Timeout (not inherited from Exception)
            raise if err.kind_of?(Interrupt) #but Interrupts should still work
            strategy=case consumer.on_error(err)
              when :ignore
                channel.ack(delivery_info.delivery_tag, false) #acknowledge and go on
                'ignored'
              when :exit
                channel.reject(delivery_info.delivery_tag, true) # requeue and stop
                @stopping=true
                'exiting'
              when :requeue
                channel.reject(delivery_info.delivery_tag, true) # requeue
                sleep @options[:requeue_sleep]
                "requeueing (#{@options[:requeue_sleep]})"
              else
                channel.reject(delivery_info.delivery_tag, true) # requeue and stop
                @stopping=true
                'unknown error strategy'
            end

            logger.error("Consumer failed (#{strategy}): #{consumer.name} #{err.message}\n#{err.backtrace.join("\n")}\n#{event.inspect}")
          end

          if @stopping
            delivery_info.consumer.cancel
          end

        end
      rescue Interrupt => errr
        logger.info("Consumer terminated (interrupt): #{consumer.name} ")
        raise #so you can stop your scripts
      ensure #on interrupt or exiting the loop close everything so there's no open connection hangigng around
        logger.debug("Consumer closing connections: #{consumer.name} ")
        channel.close
        connection.close
      end

      @stopping
    end

    def call_consumer(delivery_info, properties, body)
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
        logger.debug("Consumer consuming: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
        consumer.consume(event, info)
      rescue HopHop::Consumer::ExitLoop
        logger.info("Consumer exiting loop: #{consumer.name}")
        @stopping=true
      end

      logger.debug("Consumer acknowledged: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
      channel.ack(delivery_info.delivery_tag)
      event #return event in case of errors
    end


#this will bind to the exchange. As a sideffect it will establish the connection and create the queue
    def bind
      logger.debug "Consumer binding: #{consumer.name} -> #{consumer.bindings.inspect}"
      consumer.bindings.each do |event_pattern|
        queue.bind(exchange, :routing_key => event_pattern)
      end
      nil
    end

    attr_reader :consumer, :options

#we're always logging to the consumer's logger
    def logger
      consumer.logger
    end

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