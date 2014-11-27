module HopHop
  DEFAULT_PORT = 8787
# parses ARGV, loads the config file and calls the right commands in ConsumerCtrl
  class ConsumerBin
    KNOWN_COMMANDS = %w(start stop restart adjust check)
    # this parses argv and creates an option hash
    attr_reader :command
    attr_reader :options

    def self.run(argv)
      new(argv).run
    end

    def initialize(argv)
      options_parser.parse!(argv)
      @command = ARGV.shift
      unless KNOWN_COMMANDS.include?(@command)
        STDERR.puts "command unknown: '#{@command}' must be one of #{KNOWN_COMMANDS.join(", ")}."
        STDERR.puts options_parser
        STDERR.flush
        exit(1)
      end

      @selected_env = ENV["HOPHOP_CTRL_ENV"] || ENV["RAILS_ENV"] || ENV["RACK_ENV"] || ENV["RUBY_ENV"] || "development"

      if options[:config_file]
        @config = Config.load(options[:config_file], @selected_env,
                              :port     => @options[:port],
                              :log      => @options[:log],
                              :roles    => (@options[:roles] || []).map(&:to_sym),
                              :hostname => @options[:hostname] || `hostname`.strip
        )
      else
        $STDERR.puts "no config file given"
        exit 1
      end
    end

    def run
      ctrl = ConsumerCtrl.new(@config)
      exit ctrl.send(@command)
    end

    private

    def options_parser
      @options ||= { :port => DEFAULT_PORT, :log => "hop_hop" }
      @options_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: hop_hop --help|--version
       hop_hop (start|restart|stop|adjust|check) (--config|--port)"

        opts.separator ""
        opts.separator "options:"

        opts.on('-c', '--config FILE', "Load config from file (default: #{@options[:log].inspect})") do |file|
          @options[:config_file] = file
        end

        opts.on('-p', '--port PORT', "Spawner port (default: #{@options[:port].inspect})") do |port|
          @options[:port] = port
        end

        opts.on('-l', '--log FILE', "Where the log to (esp. STDOUT) (default: #{@options[:log].inspect})") do |file|
          @options[:log] = file
        end

        opts.on('-r', '--roles a,b,c', Array, "Which roles to fire up if not given the roles will be determined from the host configuration in the config file. Role 'all' will start everything.") do |roles|
          @options[:roles] = roles
        end

        opts.on('-h', '--host HOSTNAME', String, "Change the hostname to simulate what would happen on a given host. Default ist the result of the 'hostname' command.") do |hostname|
          @options[:hostname] = hostname
        end

        opts.on('--version', "printing the version and exits") do
          puts HopHop::VERSION
          exit 0
        end

        opts.on('--help', "print this help") do
          puts @options_parser
          exit 0
        end

      end
    end
  end
end
