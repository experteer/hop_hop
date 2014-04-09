module HopHop

  #This class should be inherited to implement a consumer for events.
  #It will ensure the queue and the bindings to the event exchange.
  #After that it will run the consume loop to get one ConsumeEvent after the other.
  #@note A consumer is instantiated only once! So instance variables don't change between callbacks.
  class Consumer
    class ExitLoop < Exception;
    end

    # @param [Hash] options options for the consumer
    # @return [Boolean] true if exit_loop was called, false if loop was exited because of an error
    def self.consume(options={})
      receiver.consume(new(options))
    end

    #the receiver is set in the environment files as is responsible to start the event loop.
    def self.receiver
      @@receiver
    end

    def self.receiver=(_receiver)
      @@receiver=_receiver
    end

    self.receiver=nil

    #This sets and gets the queue name the consumer will pop the messages.
    #@note YOU have to handle race conditions if you fire up multiple consumers on the same queue. You can use this only once
    #  per consumer.
    #@param [String] queue_name   specifies a queue we will connect to or returns the current set queue name if queue_name is nill
    #@example
    #  class TestConsumer < HopHop::Consumer
    #    queue "crm_mails"
    #  end
    def self.queue(queue_name=nil, options=nil)
      if queue_name
        @queue_options=options||{}
        @queue_name = queue_name.to_s
      else
        @queue_name
      end
    end

    def self.queue_options
      @queue_options
    end

    #This sets and gets binding the queue will be connected to.
    #@note you can use this multiple times
    #@param [String] event_names   specifies a event_name we will bind or returns the current event_names if event_name is nill
    #@note You have to prove the whole event name (i.e. subsystem+.+event name)
    #@example
    #  class TestConsumer < HopHop::Consumer
    #    bind "career.candidate.signup", :testing
    #    bind "career.caniddate.cancel"
    #  end

    def self.bind(*event_names)
      @event_names||=[]
      @event_names = (@event_names + [event_names].flatten).uniq.map(&:to_s)
      @event_names
    end

    #options
    #:bind override the bindings
    #:queue override the queue name
    #:logger
    def initialize(options={})
      @options=options
      @logger=options[:logger] || Logger.new(STDOUT)
      on_init
    end

    attr_reader :options, :logger

    #This is called befor the event loop is entered but before it's bound to the queue so you can set up some instance vars.
    #Just override it in your inherited class.
    def on_init
    end

    #This is called after the consumer is bound to the queue
    def on_bind

    end

    #this should return one of :ignore, :requeue, :exit
    #if it requeues it can also do a sleep if ot wants to or increase a counter and exit, ...
    def on_error(exception)
      :exit
    end

    def name
      "#{self.class.to_s} (#{queue})"
    end

    #This is the callback from the receiver. It will be called whenever a new message arrives.
    #@note If an exception is raised the messages will be put back into the queue (no ack) so
    # make sure you catch everything exception you want to accept.
    #@param [HopHop::ConsumeEvent] consume_event The event you should take care of.
    #@param [HopHop::QueueInfo] some infos on the queue status
    def consume(consume_event, info)
      raise "please implement to consume method"
    end

    #returns the bindings
    def bindings
      self.class.bind
      #@options[:bind] || self.class.bind
    end

    def queue
      self.class.queue || ''
      #@options[:queue] || self.class.queue
    end

    def queue_options
      self.class.queue_options
      #@options[:queue_options] || self.class.queue_options
    end

    def exit_loop
      raise ExitLoop
    end

    private
    def self.inherited subclass
      subclass.bind(@event_names.dup) if @event_names
      subclass.queue(
        @queue_name.nil? ? nil : @queue_name.dup,
        @queue_options.nil? ? nil : @queue_options.dup)
    end
  end
end