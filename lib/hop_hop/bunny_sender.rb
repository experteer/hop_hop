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
    # @option options [Integer] :heartbeat seconds (0 = none, :server means use from server, default: :server) 
    # @option options [Integer] :automatically_recover (true)
    # @option options [String]  :user (guest)
    # @option options [String]  :password (guest)
            
    def initialize(options={})
      defaults = { :host => 'localhost', :port => 5672, :exchange => 'events', :user => 'guest', :password => 'guest',
      :heartbeat => :server, :automatically_recover  => true , :ttl => nil }
      
      @options = defaults.merge(options)
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
      @connection = Bunny.new(Helper.slice_hash(options, :host, :port, :user, :password, :heartbeat, :automatically_recover ))
      @connection.start
    end
  end
end
