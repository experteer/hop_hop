module HopHop
  class QueueConnection
    attr_reader :consumer, :options

    def initialize(consumer, options={})
      @consumer=consumer
      @options=options
      @options[:prefetch] ||= 1
      @options[:requeue_sleep] ||= 5
      @exchange_name = options[:exchange] || 'events'
      bind #leave this here as on receiver.connect all bindings should be in place
    end

    # close channel and connection
    def close
      logger.debug("Consumer closing connections: #{consumer.name} ")
      channel.close
      connection.close
    end

    #@return [Boolean] true if exit_loop was called and false if interrupted
    def loop
      reset_exit_loop
      # @stopping=false #this can also be set by the call_consumer method
      normal_exit=true
      begin
        queue.subscribe(:block => true, :ack => true) do |delivery_info, properties, body|
          begin
            event = call_consumer(delivery_info, properties, body)
          rescue Object => err #I really catch everything, even Timeout (not inherited from Exception)
            raise if err.kind_of?(Interrupt) #but Interrupts should still work
            normal_exit = handle_error(event, delivery_info, err)
          end

          if exit_loop?
            delivery_info.consumer.cancel
          end
        end
      rescue Interrupt => errr
        logger.info("Consumer terminated (interrupt): #{consumer.name} ")
        raise #so you can stop your scripts
      ensure #on interrupt or exiting the loop close everything so there's no open connection hangigng around
        close
      end

      normal_exit
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
        exit_loop!
      end

      logger.debug("Consumer acknowledged: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
      channel.ack(delivery_info.delivery_tag)
      event #return event in case of errors
    end


    # this will bind to the exchange. As a sideffect it will establish the
    # connection and create the queue
    def bind
      logger.debug "Consumer binding: #{consumer.name} -> #{consumer.bindings.inspect}"
      consumer.bindings.each do |event_pattern|
        queue.bind(exchange, :routing_key => event_pattern)
      end
      nil
    end

    # we're always logging to the consumer's logger
    def logger
      consumer.logger
    end

    # Bunny Queue as set in consumer
    #
    # @note: don't call this before consumer is set
    # @return [Bunny::Queue]
    def queue
      options={:durable => true}
      options[:exclusive] = true if consumer.queue.nil? || consumer.queue.empty?
      @queue||=channel.queue(consumer.queue, options)
    end

    def exchange
      @exchange||=channel.topic(@exchange_name, :durable => true)
    end

    # Bunny channel
    # Will create and prefetch a new channel on demand
    #
    # @return [Bunny::Channel]
    def channel
      return @channel if defined?(@channel)
      @channel = connection.create_channel
      @channel.prefetch(options[:prefetch])
      @channel
    end

    # Bunny connection to RabbitMQ
    # Will start a new connection on demand
    #
    # @return [Bunny::Session] active Bunny session
    def connection
      return @connection if defined?(@connection)
      @connection = Bunny.new(:host => @options[:host], :port => @options[:port])
      @connection.start
      @connection
    end

    private
    def handle_error(event, delivery_info, error)
      normal_exit, strategy = case consumer.on_error(error)
      when :ignore
        #acknowledge and go on
        acknowledge_message(delivery_info)
        [true, 'ignored']
      when :exit
        # requeue and stop
        requeue_message(delivery_info)
        exit_loop!
        [false, 'exiting']
      when :requeue
        # requeue
        requeue_message(delivery_info)
        sleep @options[:requeue_sleep]
        [true, "requeueing (#{@options[:requeue_sleep]})"]
      else
        # requeue and stop
        requeue_message(delivery_info)
        exit_loop!
        [false, 'unknown error strategy']
      end

      logger.error("Consumer failed (#{strategy}): #{consumer.name} #{error.message}\n#{error.backtrace.join("\n")}\n#{event.inspect}")
      return normal_exit
    end

    def requeue_message(delivery_info)
      channel.reject(delivery_info.delivery_tag, true)
    end

    def acknowledge_message(delivery_info)
      channel.ack(delivery_info.delivery_tag, false)
    end

    def exit_loop?
      @exit_loop
    end
    def exit_loop!
      @exit_loop = true
    end
    def reset_exit_loop
      @exit_loop = false
    end

  end

end