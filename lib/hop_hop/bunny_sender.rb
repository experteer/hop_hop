module HopHop
  # This sends an event through Bunny
  # it jsons the data and passes the meta header as is
  class BunnySender
    attr_reader :options

    # @param [Hash] options
    # @option options [String] :host the hostname of the rabbit mq server (localhost)
    # @option options [Integer] :port the port the rabbit mq server (5672)
    # @option options [String] :exchange name of the exchange to bind to (events)
    # @option options [Integer] if set to a number the messages will timeout after this number miliseconds (nil)
    def initialize(options={ :host => 'localhost', :port => 5672, :exchange => 'events', :ttl => nil })
      @options = options
      @exchange_name = options[:events] || 'events'
    end

    # @param [Object] data is an object that responds to to_json
    # @param [Hash] meta a hash of meta informations (see HopHop::Event#meta)
    def publish(data, meta)
      meta = meta.merge(:expiration => options[:ttl]) if options[:ttl]

      exchange.publish(data.to_json, meta)
    end

  private

    def exchange
      @exchange || channel.topic(@exchange_name, :durable => true)
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      return @connection if defined?(@connection)
      @connection = Bunny.new(:host => options[:host], :port => options[:port])
      @connection.start
    end
  end
end
