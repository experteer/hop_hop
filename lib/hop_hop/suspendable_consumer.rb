
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

      def suspend_on( message )
        bind message
        self.suspend_message = message
      end

      def resume_on( message )
        @wait_consumer = Class.new(HopHop::Consumer) do
          queue self.queue
          
          bind message
          
          def consume(event, info)
            exit_loop
          end
        end
      end
    
      def consume(options = {})
        while true
          self.suspend = false
          super(options)
          if self.suspend
            @wait_consumer.consume
          else
            break
          end
        end
      end

    end

    def check_suspend(event, info)

      if event.name == self.class.suspend_message
        self.class.suspend = true
        exit_loop
      end

      true
    end

  end
end

