require 'drb/drb'
require 'logger'

# this dispatches most things to the driver
module HopHop
  class ConsumerServer
    def self.start(config)
      server = new(config)
      host_port = "localhost:#{config.control.port}"
      uri = "druby://#{host_port}"
      DRb.start_service(uri, server)
      config.driver.do_logger(config).info "Consumer server started"
      # workaround: joining main thread in rubinius crashes signal handling
      # DRb.thread.join
      while DRb.primary_server
        sleep 1
      end
    end

    def initialize(config)
      @config = config
      @config.driver.do_setup(config)
      @forked = 0
    end

    # @param [String] consumer_class_name name of the consumer class to start (has to have a config)
    # @param [integer] instances how many instances to fire up (not taken from the config)
    def consumer(consumer_class_name, required_count_running)
      consumer_config = @config.consumers[consumer_class_name]
      return unless consumer_config

      instance_ids = instances(consumer_config.class_name)
      count_running = instance_ids.size
      # TODO: just the number of instances of my role!
      started = 0
      removed = 0

      case
        when required_count_running == count_running
          puts "Consumer no fix:  #{consumer_config.name} (#{required_count_running}/#{consumer_config.instances}/#{count_running})"
          return nil
        when required_count_running > count_running
          puts "Consumer need starts:  #{consumer_config.name} (#{required_count_running}/#{consumer_config.instances}/#{count_running})"
          1.upto(required_count_running - count_running) do
            started += 1
            @config.driver.do_start(@config, consumer_config)
          end
        when required_count_running < count_running
          puts "Consumer need stops:  #{consumer_config.name} (#{required_count_running}/#{consumer_config.instances}/#{count_running})"
          1.upto(count_running - required_count_running) do |idx|
            removed += 1
            pid = instance_ids[idx - 1]
            @config.driver.do_stop(@config, consumer_config, pid)
          end
        else
          raise "WTF"
      end
      { :started => started, :removed => removed }
    end

    # @return [Hash] returns an array identifiers
    def instances(consumer_class_name)
      consumer_config = @config.consumers[consumer_class_name]
      return [] unless consumer_config
      @config.driver.instance_ids(@config, consumer_config)
    end

    def ping
      "pong"
    end

    def finish
      logger.info "exiting"
      # should we try to stop the child processes?
      DRb.stop_service
    end

    private
    def logger
      @logger ||= @config.driver.do_logger(@config)
    end
  end
end
