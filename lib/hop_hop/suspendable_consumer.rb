
module HopHop

  # special form of a consumer that is able to suspend message consumption
  # with a control message and resume on another.
  # 
  # the messages for supend and resume have to be declared using
  # suspend_on and resume_on. Currently you can only have one message
  # for each task
  #
  # note that the continue message must not be sent before the 
  # the consumer was suspended. when sent to early, the message is
  # lost. It is no problem in that case, to send another one.
  class SuspendableConsumer < HopHop::Consumer

    before_filter :check_suspend

    class << self
      attr_accessor :suspend_message, :suspend

      # declare the message that suspends the consumer
      def suspend_on( message )
        bind message
        self.suspend_message = message
      end

      # declare the message that resumes the consumer
      #
      # the method creates an additional, unnamed consumer
      # that does nothing but wait for the first message
      # on a temporary queue and terminate
      def resume_on( message )
        @wait_consumer = Class.new(HopHop::Consumer) do
          
          bind message
          
          def consume(event, info)
            exit_loop
          end
        end
      end

      # message processing handling the suspend option 
      # @param [Hash] options options for the consumer
      # @return [Boolean] true if exit_loop was called, false if loop was exited because of an error
      def consume(options = {})
        while true
          self.suspend = false
          ret = super(options)
          if self.suspend
            @wait_consumer.consume
          else
            return ret
          end
        end
      end

    end

    private
    # process suspend messages before normal message processing
    def check_suspend(event, info)

      if event.name == self.class.suspend_message
        self.class.suspend = true
        exit_loop
      end

      true
    end

  end
end

