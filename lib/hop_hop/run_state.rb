module HopHop
  # RunState gathers some info about how many instances are running of a special
  # consumer (config). And can also fix this (perhaps this is a little bit too much for on class).
  class RunState
    PROCESS_WAIT = 0.2
    PROCESS_MAX_TRIES = 30

    attr_reader :running_pids

    # @option [Integer] :port
    def initialize(config, options={})
      @config = config
      @running_pids = nil
      set_running_pids
      @options = options
    end

    # just a shortcat to the consumer's name
    # @return [String] name of consumer as defined in config
    def name
      @config.name
    end

    def to_s
      "#{name} : #{count_running}/#{@config.instances} running:#{@running_pids.inspect}"
    end

    def count_running
      @running_pids.size
    end

    def fix(testing=false, force_required_count_running=nil)
      required_count_running = force_required_count_running || @config.instances
      started = 0
      removed = 0

      case
        when required_count_running == count_running
          return nil
        when required_count_running > count_running
          1.upto(required_count_running - count_running) do
            started += 1
            if testing
              #          puts @config.ruby_start_cmd
            else
              # the spawserver should run this (memory efficiency, start up time)
              drb_server.exec(@config.to_hash,
                              :as => "hop_hop consumer --identifier #{@options[:identifier]} #{name}")
            end
          end
        when required_count_running < count_running
          1.upto(count_running - required_count_running) do |idx|
            removed += 1
            cmd = "kill -TERM #{running_pids[idx - 1]}"
            if testing
              #           puts cmd
            else
              # we're killing them directly though perhaps the spwan server could do this for us
              system(cmd)
            end
          end
        else
          raise "WTF"
      end

      wait_for_process(required_count_running) unless testing # wait for process list changes only if not in testing mode

      { :started => started, :removed => removed } # perhaps an object would be better
    end

  private
    def wait_for_process(required_count_running)
      tries = 0

      while tries < PROCESS_MAX_TRIES # max_wait = wait*max_tries (0.2 * 30 = 30 sec)
        set_running_pids
        break if required_count_running == count_running
#      $stdout.write "."
        sleep PROCESS_WAIT
        tries += 1
      end
    end

    def set_running_pids
      name_regexp = Regexp.new(name)
      running_pids = nil
      tries = 0
      begin
        @running_pids = Sys::ProcTable.ps.select{ |proc| proc.cmdline =~ name_regexp }.map(&:pid)
      rescue Errno::ENOENT, Errno::EINVAL, Errno::ESRCH
        tries += 1
        sleep(0.1 * tries)
        retry unless tries > 3
      end
      @running_pids.sort!
    end

    def drb_server
      @options[:spawner_server]
    end
  end
end
