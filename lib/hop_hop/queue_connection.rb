module HopHop
  class QueueConnection
    attr_reader :consumer, :options

    def initialize(consumer, options={})
      @consumer = consumer
      @options = options
      @options[:prefetch] ||= 1
      @options[:requeue_sleep] ||= 5
      @exchange_name = options[:exchange] || 'events'
      bind # leave this here as on receiver.connect all bindings should be in place
    end

    # close channel and connection
    def close
      logger.debug("Consumer closing connections: #{consumer.name} ")
      channel.close
      connection.close
    end

    # @return [Boolean] true if exit_loop was called and false if interrupted
    def loop
      reset_exit_loop
      normal_exit = true
      begin
        queue.subscribe(:block => true, :ack => true) do |delivery_info, properties, body|
          begin
            event = call_consumer(delivery_info, properties, body)
          rescue Object => err
            # I really catch everything, even Timeout (not inherited from Exception)
            raise if err.kind_of?(Interrupt) # but Interrupts should still work
            normal_exit = handle_error(event, delivery_info, err)
          end

          delivery_info.consumer.cancel if exit_loop?
        end
      rescue Interrupt
        logger.info("Consumer terminated (interrupt): #{consumer.name} ")
        raise # so you can stop your scripts
      ensure
        # on interrupt or exiting the loop close everything so there's no open
        # connection hangigng around
        close
      end

      normal_exit
    end

    def call_consumer(delivery_info, properties, body)
      event = HopHop::ConsumeEvent.new(JSON.parse(body),
                                       metadata(delivery_info, properties))
      info = QueueInfo.new(self)

      begin
        logger.debug("Consumer consuming: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
        if consumer.run_before_filters(event,info) != false
          consumer.consume(event, info)
        end
      rescue HopHop::Consumer::ExitLoop
        logger.info("Consumer exiting loop: #{consumer.name}")
        exit_loop!
      end

      logger.debug("Consumer acknowledged: #{consumer.name} - #{event.name} '#{delivery_info.delivery_tag}'")
      acknowledge_message(delivery_info)
      event # return event in case of errors
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
      options = { :durable => true }
      options[:exclusive] = true if consumer.queue.nil? || consumer.queue.empty?
      @queue ||= channel.queue(consumer.queue, options)
    end

    def exchange
      @exchange ||= channel.topic(@exchange_name, :durable => true)
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
      @connection = Bunny.new(Helper.slice_hash(@options, :host, :port, :virtual_host, :heartbeat, 
                                                :automatically_recover,:user,:password))
      @connection.start
      @connection
    end

  private

    def metadata(delivery_info, properties)
      {
        :routing_key => delivery_info.routing_key,
        :timestamp   => properties.timestamp,
        :headers     => {
          :producer => properties.headers["producer"],
          :version  => properties.headers["version"]
        }
      }
    end

    def handle_error(event, delivery_info, error)
      normal_exit, strategy = case consumer.on_error(error)
                              when :ignore
                                on_error_ignore(delivery_info)
                              when :exit
                                on_error_exit(delivery_info)
                              when :requeue
                                on_error_requeue(delivery_info)
                              else
                                on_error_stop(delivery_info)
                              end

      logger.error(<<-EOF)
Consumer failed (#{strategy}): #{consumer.name} #{error.message}
#{error.backtrace.join("\n")}
#{event.inspect}
EOF
      normal_exit
    end

    # acknowledge and go on
    def on_error_ignore(delivery_info)
      acknowledge_message(delivery_info)
      [true, 'ignored']
    end

    # requeue and stop
    def on_error_exit(delivery_info)
      requeue_message(delivery_info)
      exit_loop!
      [false, 'exiting']
    end

    # requeue
    def on_error_requeue(delivery_info)
      requeue_message(delivery_info)
      sleep @options[:requeue_sleep]
      [true, "requeueing (#{@options[:requeue_sleep]})"]
    end

    # requeue and stop
    def on_error_stop(delivery_info)
      requeue_message(delivery_info)
      exit_loop!
      [false, 'unknown error strategy']
    end

    # Reject Message and requeue it
    def requeue_message(delivery_info)
      channel.reject(delivery_info.delivery_tag, true)
    end

    # Acknowledge message
    # don't acknowledge other older unack'ed messages
    def acknowledge_message(delivery_info)
      channel.ack(delivery_info.delivery_tag)
    end

    attr_reader :exit_loop
    alias_method :exit_loop?, :exit_loop

    def exit_loop!
      @exit_loop = true
    end

    def reset_exit_loop
      @exit_loop = false
    end
  end
end
