require 'drb/drb'
require 'logger'

# this dispatches most things to the driver
module HopHop
  class ConsumerServer
    def self.start(config)
      server = new(config)
      host_port = "#{config.control.host}:#{config.control.port}"
      uri = "druby://#{host_port}"
      DRb.start_service(uri, server)
      config.driver.do_logger(config).info "Consumer server started"
      DRb.thread.join
    end

    def initialize(config)
      @config = config
      @config.driver.do_setup(config)
      @forked = 0
    end

    def consumer(consumer_class_name, instances = nil)
      consumer_config = @config.consumers[consumer_class_name]
      required_count_running = instances || consumer_config.instances

      instance_ids = instances(consumer_config.class_name)
      count_running = instance_ids.size
      # TODO: just the number of instances of my role!
      started = 0
      removed = 0

      case
        when required_count_running == count_running
          return nil
        when required_count_running > count_running
          1.upto(required_count_running - count_running) do
            started += 1
            @config.driver.do_start(@config, consumer_config)
          end
        when required_count_running < count_running
          1.upto(count_running - required_count_running) do |idx|
            removed += 1
            @config.driver.do_stop(@config, consumer_config, instance_ids[idx - 1])
          end
        else
          raise "WTF"
      end
      { started: started, removed: removed }
    end

    # @return [Hash] returns an array identifiers
    def instances(consumer_class_name)
      consumer_config = @config.consumers[consumer_class_name]
      name_regexp = Regexp.new("--identifier #{@config.control.identifier} #{consumer_config.name}")
      tries = 0
      begin
        running_pids = Sys::ProcTable.ps.select { |proc| proc.cmdline =~ name_regexp }.map(&:pid)
        running_pids.sort
      rescue Errno::ENOENT, Errno::EINVAL, Errno::ESRCH
        tries += 1
        sleep(0.1 * tries)
        retry unless tries > 3
        nil
      end
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
