module HopHop
  class ConsumerCtrl
    # @param [HopHop::Config] config
    def initialize(config)
      @config = config
      @server_ctrl = ServerCtrl.new(config)
    end

    def check(testing = true)
      exit_value = 0
      with_each_consumer do |info|
        exit_value = 1 if info.needs_fix?
        puts info
      end
      exit_value # =1 if fixing is needed
    end

    def adjust
      exit_value = 0
      with_each_consumer do |info, consumer_config|
        if info.needs_fix?
          exit_value = 1
          @server_ctrl.consumer(consumer_config) # adjust
          info = @server_ctrl.run_state(consumer_config)
        end
        puts info
      end
      exit_value # =1 if fixing is needed
    end

    # no roling restart (stop everything first then start everything new)
    def restart
      exit_value = 0

      @server_ctrl.stop
      with_each_consumer do |info, consumer_config|
        @server_ctrl.consumer(consumer_config) # start the configured instances
        info = @server_ctrl.run_state(consumer_config)
        puts info # info after changing
      end

      exit_value
    end

    alias_method :start, :restart

    def stop
      exit_value = 0
      with_each_consumer do |info, consumer_config|
        @server_ctrl.consumer(consumer_config, 0) # adjust
        info = @server_ctrl.run_state(consumer_config)
        puts info # info after changing
      end
      @server_ctrl.stop
      exit_value
    end

    private

    def with_each_consumer
      @config.consumers.each do |class_name, consumer_config|
        yield @server_ctrl.run_state(consumer_config), consumer_config
      end
    end
  end
end
