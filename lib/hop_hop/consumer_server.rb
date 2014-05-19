# ###this needs some moving out
require 'drb/drb'
require 'logger'

module HopHop
  class ConsumerServer
    CONSUMER_SERVER_DEFAULT_HOST_PORT = "localhost:8787"
    attr_reader :hooks, :host_port

    def initialize(options={})
      @hooks = options[:hooks]
      @host_port = options[:host_port] || CONSUMER_SERVER_DEFAULT_HOST_PORT
      @hooks.setup_fork(options)
      @forked = 0
    end

    def logger
      @hooks.logger
    end
    # @param [String] code The code to be executed
    # @param [Hash] options some options
    # @option options [String] :as the String as wich the process will show up in the process list
    def exec(cmd, options={})
      # puts "P: 1 #{Time.now} #{code}"
      @forked += 1
      hooks.before_fork(cmd)
      pid = fork do
        if options[:as]
          $0 = options[:as]
        end
        hooks.after_fork(cmd)
        logger.info "FORK(#{@forked}): '#{cmd.inspect}' #{options.inspect}"
        @hooks.run(cmd, options)
      end
      Process.detach(pid)
      pid
    end

    def ping
      "pong"
    end

    def finish
      logger.info "exiting"
      # should we try to stop the child processes?
      DRb.stop_service
    end

    def self.start(options)
      server = new(options)
      host_port = options.delete(:host_port) || CONSUMER_SERVER_DEFAULT_HOST_PORT
      uri = "druby://#{host_port}"
      DRb.start_service(uri, server)
      server.logger.info "Consumer server started"
      DRb.thread.join
    end
  end
end
