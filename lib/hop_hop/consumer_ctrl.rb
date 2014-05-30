module HopHop
  class ConsumerCtrl
    # @param [HopHop::ConsumersConfig] consumer_configs
    # @param [Hash] options
    # @option options [String] :log name of the logfile for stdout
    # @option options [Integer] :port port of the hop hop fork server to run
    def initialize(consumer_configs, options={})
      @consumer_configs = consumer_configs
      @options = options
    end

    def check(testing=true)
      exit_value = 0
      with_each_consumer do |info|
        exit_value = 1 if info.fix(testing)
        puts info
      end
      exit_value # =1 if fixing is needed
    end

    def adjust
      ensure_spawner
      check(false)
    end

    # no roling restart (stop everything first then start everything new)
    def restart
      exit_value = 0

      stop
      ensure_spawner

      with_each_consumer do |info|
        info.fix
        puts info
      end

      exit_value
    end

    alias_method :start, :restart

    def stop
      exit_value = 0
      with_each_consumer do |info|
        info.fix(false, 0)
        if info.running_pids != []
          exit_value = 1
        end
        puts info
      end
      ensure_no_spawner
      exit_value
    end

  private

    def with_each_consumer
      @consumer_configs.consumers.each do |consumer_config|
        runstate = RunState.new(consumer_config,
                                :spawner_server => spawner_server,
                                :identifier     => @consumer_configs.identifier)
        yield runstate
      end
    end

    def spawner_server
      @spawner_server ||= DRbObject.new_with_uri(server_uri)
    end

    def server_uri
      "druby://localhost:#{server_port}"
    end

    def server_port
      @consumer_configs.port || @options[:port] || DEFAULT_PORT
    end

    def spawner_alive?
      spawner_server.ping
      true
    rescue DRb::DRbConnError
      false
    end

    def ensure_no_spawner
      if spawner_alive?
        spawner_server.finish
        wait_unless(@consumer_configs.wait_spinup){ spawner_alive? } # now wait for it to spin up
        raise "Could not spin down the fork server" if spawner_alive?
      end
    end

    def ensure_spawner
      unless spawner_alive?
        # spawn this: TBD make this a config!

        pid = Process.fork do
          cmd = "hop_hop server --identifier #{@consumer_configs.identifier}"
          puts "starting #{cmd}"
          $0 = cmd
          HopHop::ConsumerServer.start(@consumer_configs.server_config.merge(
                                         :host_port => "localhost:#{server_port}",
                                         :log       => @options[:log])
          )
        end

        Process.detach(pid) # so we leave no zombies behind
        wait_unless(@consumer_configs.wait_spinup){ !spawner_alive? } # now wait for it to spin up
        raise "Could not spin up the fork server" unless spawner_alive?
      end
    end

    def wait_unless(seconds, sleep_time=0.5)
      tries = seconds / sleep_time
      while yield && tries > 0
        tries -=  1
        sleep sleep_time
        # STDOUT.write(".")
      end
    end
  end
end
