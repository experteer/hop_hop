module HopHop

  #This class should be inherited to implement a consumer for events.
  #It will ensure the queue and the bindings to the event exchange.
  #After that it will run the consume loop to get one ConsumeEvent after the other.
  #@note A consumer is instantiated only once! So instance variables don't change between callbacks.
  class Consumer
    class ExitLoop < Exception;
    end

    #@param [Hash] options options for the consumer
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
    def initialize(options={})
      @options=options
      setup
    end

    attr_reader :options

    #This is called befor the event loop is entered so you can set up some instance vars.
    #Just override it in your inherited class.
    def setup
    end

    #This is called after the consumer is connected to the queue
    def after_connect

    end

    def name
      "#{self.class.to_s} (#{queue})"
    end

    #This is the callback from the receiver. It will be called whenever a new message arrives.
    #@note If an exception is raised the messages will be put back into the queue (no ack) so
    # make sure you catch everything exception you want to accept.
    #@param [HopHop::ConsumeEvent] consume_event The event you should take care of.
    def consume(consume_event)
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
  end
end