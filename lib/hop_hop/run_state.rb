module HopHop
  # RunState gathers some info about how many instances are running of a special
  # consumer (config). And can also fix this (perhaps this is a little bit too much for on class).
  class RunState
    attr_reader :running_pids

    # @option [Integer] :port
    def initialize(consumer_config, consumer_identifiers)
      @config = consumer_config
      @running_pids = consumer_identifiers # doesn't have to be pids but some identifiers
    end

    # just a shortcat to the consumer's name
    # @return [String] name of consumer as defined in config
    def name
      @config.name
    end

    def to_s
      "#{name} : #{count_running}/#{@config.instances} running:#{@running_pids.inspect}"
    end

    def instance_diff
      @config.instances - count_running
    end

    def needs_fix?
      instance_diff != 0
    end

    def count_running
      @running_pids.size
    end

    private
    # TODO: move this where?
# wait for process list changes only
#       if not
#         in testing mode
#         wait_for_process(required_count_running) unless testing
#
#         {:started => started, :removed => removed} # perhaps an object would be better
#       end
#
#     end

#    def wait_for_process(required_count_running)
#      tries = 0
#
#      while tries < PROCESS_MAX_TRIES # max_wait = wait*max_tries (0.2 * 30 = 30 sec)
#        set_running_pids
#        break if required_count_running == count_running
##      $stdout.write "."
#        sleep PROCESS_WAIT
#        tries += 1
#      end
#    end
  end
end
