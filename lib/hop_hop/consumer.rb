module HopHop
  # This class should be inherited to implement a consumer for events.
  # It will ensure the queue and the bindings to the event exchange.
  # After that it will run the consume loop to get one ConsumeEvent after the other.
  # @note A consumer is instantiated only once! So instance variables don't change between callbacks.
  class Consumer
    class ExitLoop < Exception
    end

    class << self
      # @param [Hash] options options for the consumer
      # @return [Boolean] true if exit_loop was called, false if loop was exited because of an error
      def consume(options={})
        receiver.consume(new(options))
      end

      # the receiver is set in the environment files as is responsible to start the event loop.
      def receiver
        @@receiver ||= nil
      end

      def receiver=(value)
        @@receiver = value
      end

      # This sets and gets the queue name the consumer will pop the messages.
      # @note YOU have to handle race conditions if you fire up multiple consumers
      #  on the same queue. You can use this only once per consumer.
      # @param [String] queue_name  specifies a queue we will connect to or
      #                             returns the current set queue name if queue_name is nill
      # @example
      #  class TestConsumer < HopHop::Consumer
      #    queue "crm_mails"
      #  end
      def queue(queue_name=nil, options=nil)
        if queue_name
          @queue_options = options || {}
          @queue_name = queue_name.to_s
        else
          @queue_name
        end
      end

      attr_reader :queue_options, :before_filters

      # This sets and gets binding the queue will be connected to.
      # @note you can use this multiple times
      # @param [String] event_names   specifies a event_name we will bind or
      #                               returns the current event_names if event_name is nill
      # @note You have to prove the whole event name (i.e. subsystem+.+event name)
      # @example
      #  class TestConsumer < HopHop::Consumer
      #    bind "career.candidate.signup", :testing
      #    bind "career.caniddate.cancel"
      #  end

      def bind(*event_names)
        @event_names ||= []
        @event_names = (@event_names + [event_names].flatten).uniq.map(&:to_s)
        @event_names
      end

      # declare before filter to be called before the consume method is called.
      # before filter are called with event and info parameters (as consume) 
      # before filter may call exit_loop to terminate the consumer,
      # return false to terminate the event processing or anything else
      # to continue
      #
      # @param [Symbol, String, Array<Symbol, String>] methods to be called as before filter
      def before_filter(*methods)
        @before_filters ||= []
        @before_filters = (@before_filters + [methods].flatten.map(&:to_sym)).uniq
        @before_filters
      end

      def inherited(subclass)
        subclass.bind(@event_names.dup) if @event_names
        subclass.before_filter(@before_filters) if @before_filters
        subclass.queue(
          @queue_name.nil? ? nil : @queue_name.dup,
          @queue_options.nil? ? nil : @queue_options.dup)
      end
    end

    # options
    #:bind override the bindings
    #:queue override the queue name
    #:logger
    def initialize(options={})
      @options = options
      @logger = options[:logger] || Logger.new(STDOUT)
      on_init
    end

    attr_reader :options, :logger

    # This is called befor the event loop is entered but before it's bound to
    # the queue so you can set up some instance vars.
    # Just override it in your inherited class.
    def on_init
    end

    # This is called after the consumer is bound to the queue
    def on_bind
    end

    # this should return one of :ignore, :requeue, :exit
    # if it requeues it can also do a sleep if ot wants to or increase a counter and exit, ...
    def on_error(_exception)
      :exit
    end

    def name
      "#{self.class} (#{queue})"
    end

    # run before filters
    # @return false if any of the filters returns false, true otherwise
    def run_before_filters(event, info)
      return unless self.class.before_filters
      self.class.before_filters.each do | filter |
        return false if send(filter, event, info) == false
      end
      true
    end

    # This is the callback from the receiver. It will be called whenever a new message arrives.
    # @note If an exception is raised the messages will be put back into the queue (no ack) so
    # make sure you catch everything exception you want to accept.
    # @param [HopHop::ConsumeEvent] consume_event The event you should take care of.
    # @param [HopHop::QueueInfo] some infos on the queue status
    def consume(_consume_event, _info)
      raise "please implement to consume method"
    end

    # returns the bindings
    def bindings
      self.class.bind
      # @options[:bind] || self.class.bind
    end

    def queue
      self.class.queue || ''
      # @options[:queue] || self.class.queue
    end

    def queue_options
      self.class.queue_options
      # @options[:queue_options] || self.class.queue_options
    end

    def exit_loop
      raise ExitLoop
    end
  end
end
