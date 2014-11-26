module HopHop
  class Config
    class HostsContainerConfig
      def initialize
        @hosts = Hash.new do |hash, key|
          hash[key.to_s] = []
        end # name => roles
      end

      def add(name, roles)
        @hosts[name.to_s] = @hosts[name.to_s].concat(Array(roles))
      end

      def roles_of_host(host)
        @hosts[host.to_s]
      end

      def each
        @hosts.each_pair do |hostname, roles|
          yield hostname, roles
        end
      end
    end

    class ControlConfig
      DEFAULTS = { port: 8787, wait_spinup: 60, host: 'localhost' }

      attr_reader :port, :identifier, :wait_spinup, :host
      attr_writer :port

      def initialize(env, attributes)
        @attributes = DEFAULTS.merge(attributes)
        @attributes.each_pair do |att, value|
          instance_variable_set("@#{att}", value)
        end
        @identifier = "#{env}-#{@identifier}"
      end

      def valid?
        @port && @identifier && @wait_spinup && @host == 'localhost'
      end

      def validate!
        raise "Invalid control config port, identifier, wait_spinup, host must be set. host currently has to be 'localhost'" unless valid?
      end

      def to_hash
        @attributes
      end
    end

    class ConsumersContainerConfig
      def initialize
        @consumers = {}
      end

      def add(class_name, options)
        # puts "adding: #{class_name}"
        @consumers[class_name.to_s] = ConsumerConfig.new(class_name, options)
      end

      def [](class_name)
        @consumers[class_name.to_s]
      end

      def of_role(role)
        configs = []
        role = role.to_sym

        each do |class_name, config|
          configs << config if config.role == role
        end
        configs
      end

      def each
        @consumers.each_pair do |class_name, config|
          yield class_name, config
        end
      end
    end

    class ConsumerConfig
      # instances, name, class_name, args
      def initialize(class_name, opts)
        @class_name = class_name
        @opts = opts
      end

      attr_reader :class_name

      def name
        @opts[:name] || filename.gsub('/', '_')
      end

      def instances
        @opts[:instances] || 1
      end

      def args
        @opts[:args] || {}
      end

      def filename
        @opts[:file_name] || HopHop::Helper.underscore(class_name)
      end

      def role
        @opts[:role].to_sym
      end

      def to_hash
        { filename: filename,
          class_name: class_name,
          args: args,
          name: name,
          role: role
        }
      end
    end

    class Reader
      def self.read(filename, env)
        content = File.read(filename)
        extracted = new(content, filename, env)
        extracted.config
      end

      attr_reader :env

      def initialize(content, filename, env)
        @env = env
        @control = nil
        @hosts = HostsContainerConfig.new
        @consumers = ConsumersContainerConfig.new
        @driver = nil
        @root = nil
        instance_eval(content, filename)
      end

      def config
        { control: @control,
          driver: @driver,
          consumers: @consumers,
          hosts: @hosts,
          root: @root }
      end

      def root(filename)
        @root = Pathname.new(filename)
      end

      def control(attributes = nil)
        if attributes
          @control = ControlConfig.new(@env, attributes)
          @control.validate!
        else
          @control
        end
      end

      def driver(driver_name, &block)
        driver_class_name = "HopHop::Drivers::#{HopHop::Helper.camelize(driver_name)}"
        filename = "hop_hop/drivers/#{driver_name}"
        require filename
        @driver = HopHop::Helper.constantize(driver_class_name).new(&block)
      end

      def consumer(class_name, options)
        @consumers.add(class_name, options)
      end

      def host(hostname, options)
        @hosts.add(hostname, options[:role])
      end
    end # Reader

    # creates a config for an environment
    def self.load(filename, env, overrides = {})
      env = env.to_s
      config = Reader.read(filename.to_s, env)
      new(env, config, overrides) # no need to map further
    end

    # the consumer to run with their configuration
    attr_reader :consumers

    # how to talk to the runner daemon
    attr_reader :control

    # wich kind of runner do we have
    attr_reader :driver

    # what to run on wich host
    attr_reader :hosts

    # what is the root of the project (everything should be relative to this)
    attr_reader :root

    # @params [String] env environment name
    # @param [Hash] options
    # @option overrides [String] :log name of the logfile for stdout
    # @option overrides [Integer] :port port of the hop hop fork server to run
    def initialize(env, config_hash, overrides = {})
      @env = env
      @attributes = config_hash
      @attributes.each_pair do |att, value|
        instance_variable_set("@#{att}", value)
      end
      @control.port = overrides[:port] if overrides[:port]
      @driver.stdout_filename { root.join(overrides[:log]) } if  overrides[:log]
    end
  end
end
