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

    def initialize(options = {})
      defaults = { host: 'localhost', port: 5672, exchange: 'events', user: 'guest', password: 'guest',
                   heartbeat: :server, automatically_recover: true, ttl: nil }

      @options = defaults.merge(options)
      @exchange_name = options[:events] || 'events'
      @channel_mutex = Monitor.new
      exchange
    end

    # @param [Object] data is an object that responds to to_json
    # @param [Hash] meta a hash of meta informations (see HopHop::Event#meta)
    def publish(data, meta)
      @channel_mutex.synchronize do
        meta = meta.merge(expiration: options[:ttl]) if options[:ttl]
        tries = 3
        begin
          exchange.publish(data.to_json, meta)
            # I have to rescue these and retry as bunny's autoreconnect sometimes simply doesn't work
            # TBD: logging this would be good
        rescue Bunny::ConnectionClosedError, Bunny::ChannelAlreadyClosed
          sleep 0.3
          tries -= 1
          reset
          tries >= 0 ? retry : raise
        end
      end
    end

    def reset
      @channel_mutex.synchronize do
        @exchange = @channel = @connection = nil
        exchange
      end
    end

    private

    def exchange
      @exchange ||= channel.topic(@exchange_name, durable: true)
    end

    def channel
      @channel ||= connection.create_channel
    end

    def connection
      return @connection if @connection
      @connection = Bunny.new(Helper.slice_hash(options, :host, :port, :user, :password, :heartbeat, :automatically_recover)).start
    end

  end
end
