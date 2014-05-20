module HopHop
  class ConsumersConfig
    class Reader
      def self.read(filename, env)
        content = File.read(filename)
        extracted = new(content, filename, env)
        extracted.config
      end

      def initialize(content, filename, env)
        @env = env
        instance_eval(content, filename)
      end

      def config
        return @config if defined?(@config)
        configuration = @raw_config[:env][@env]
        consumers = configuration.map do |hash|
          cfg = @raw_config[:consumers][hash[:name]]
          HopHop::ConsumerConfig.new(hash.merge(cfg))
        end
        @config = { :consumers     => consumers,
                    :identifier    => @raw_config[:identifier],
                    :port          => @raw_config[:port],
                    :server_config => @raw_config[:server_config]
        }
      end

    private

      def hop_hop_config=(hash)
        @raw_config = hash
      end
    end # Reader

    # creates a config for an environment
    def self.load(filename, env)
      env = env.to_s
      config = Reader.read(filename, env)
      new(env, config) # no need to map further
    end

    # the consumer to run with their configuration
    attr_reader :consumers
    # the identifier for all consumers/spawners
    attr_reader :identifier
    # port of the spawner daemon
    attr_reader :port
    # configuration hash for the forking server
    attr_reader :server_config
    def initialize(env, config_hash)
      @consumers = config_hash[:consumers]
      @identifier = "#{env}-#{config_hash[:identifier]}"
      @port = config_hash[:port]
      @server_config = config_hash[:server_config]
    end
  end
end
