module HopHop
  # RunState gathers some info about how many instances are running of a special
  # consumer (config). And can also fix this (perhaps this is a little bit too much for on class).
  class RunState
    attr_reader :running_pids

    # @param [ConsumerConfig] config
    # @param [Array] consumer_identifiers an Array of Strings identifying the instances
    # @param [Integer] instances numer of instances running
    def initialize(consumer_config, consumer_identifiers, instances)
      @config = consumer_config
      @running_pids = consumer_identifiers # doesn't have to be pids but some identifiers
      @instances = instances # how many instances do we expect?
    end

    # just a shortcat to the consumer's name
    # @return [String] name of consumer as defined in config
    def name
      @config.name
    end

    def to_s
      "#{name} #{'*' if needs_fix? }: #{count_running}/#{@instances} running:#{@running_pids.inspect}"
    end

    def instance_diff
      @instances - count_running
    end

    def needs_fix?
      instance_diff != 0
    end

    def count_running
      @running_pids.size
    end
  end
end
