module HopHop
  # this thing controls the server ( sending commands to it) and even starting it (this is very specific to a certain kind of servers e.g. rails_prefork)
  # @param HopHop::Config config
  class ServerCtrl
    def initialize(config)
      @config = config
    end

    def consumer(consumer_config, instances = nil)
      server.consumer(consumer_config.class_name, instances)
    end

    def run_state(consumer_config)
      RunState.new(consumer_config, get_runstate(consumer_config))
    end

    def alive?
      server.ping
      true
    rescue DRb::DRbConnError
      false
    end

    def stop
      if alive?
        server.finish
        HopHop::Helper.wait_unless(@config.control.wait_spinup) { alive? } # now wait for it to spin up
        raise "Could not stop the server" if alive?
      end
    end

    private
    def server
      @server ||= DRbObject.new_with_uri(server_uri)
    end

    def server_uri
      "druby://#{@config.control.host}:#{@config.control.port}"
    end

    # @return [Array] returns an array of identifiers
    def get_runstate(consumer_config)
      ensure_server
      server.instances(consumer_config.class_name)
    end

    # this doesn't work with every server
    def ensure_server
      unless alive?
        if @config.driver.startable?
          @config.driver.start_server(@config, self)
        else
          raise "server is not running and is not startable by client"
        end
      end
    end
  end
end