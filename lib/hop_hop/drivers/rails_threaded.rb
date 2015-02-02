module HopHop
  module Drivers
    class RailsThreaded < BaseDriver
      def startable?
        true
      end

      # TODO: don't depend on server_ctrl
      def start_server(config, server_ctrl)
        pid = Process.fork do
          cmd = "hop_hop server --identifier #{config.control.identifier}"
          # puts "starting #{cmd}"
          $0 = cmd
          HopHop::ConsumerServer.start(config)
        end

        Process.detach(pid) # so we leave no zombies behind
        HopHop::Helper.wait_unless(config.control.wait_spinup){!server_ctrl.alive?} # now wait for it to spin up
        raise "Could not spin up the consumer server" unless server_ctrl.alive?
      end

      # expect options:
      def valid?
        raise ":rails_root not set for rails_threaded" unless @options[:rails_root]
        raise ":rails_root #{@options[:rails_root]} doesn't exist" unless File.exist?(@options[:rails_root])
      end

      # DSL:
      def setup(&block)
        @options[:setup] = block
      end


      def consumer_logger(&block)
        @options[:consumer_logger] = block
      end

      def stdout_filename(&block)
        @options[:stdout_filename] = block
      end

      def stdout_filename(&block)
        @options[:stdout_filename] = block
      end

      def logger(&block)
        @options[:logger] = block
      end

      # Runtime:
      # TODO: instanciating a new object with config would be better
      def do_setup(config)
        require File.join(config.root.join('config', 'environment'))

        # force eager load of Rails and application irrespective of config
        # context: require 'source' is not atomic or thread-safe, i.e. race conditions can occur if a class is required inside multiple threads at the same time
        rc = Rails.application.config
        rc.eager_load_namespaces.each(&:eager_load!) unless rc.eager_load # if true, already happened

        filename = call_hook(:stdout_filename)
        # puts "stdout to: #{filename} #{Rails.root}"

        if filename
          STDIN.reopen("/dev/null")
          STDOUT.reopen(filename, "a")
          STDERR.reopen(STDOUT)
        end
        puts "starting rails"
        call_hook(:setup)
      end

      def do_logger(config)
        call_hook(:logger)
      end


      def do_stop(config, consumer_config, pid)

        consumer_thread = consumer_threadgroups[consumer_config.name].find do |thread|
          thread.instance_variable_get(:@thread_id) == pid
        end

        if consumer_thread
          puts "Stopping: #{consumer_thread}"
          consumer_thread.exit

          tries = 1
          while consumer_thread.alive? && tries < 10 do
            sleep(0.1 * tries)
            tries += 1
          end
          if consumer_thread.alive?
            puts "Stopping thread failed: #{consumer_thread}"
          end
        end
      end

      def do_start(config, consumer_config)
        run(consumer_config)
      end

      def instance_ids(config, consumer_config)
        running_threads = consumer_threadgroups[consumer_config.name].map { |thr| thr.instance_variable_get :@thread_id}
      end

      private

      def run(consumer_config)
        require consumer_config.filename
        # run the consumer and give it a logger
        if @options[:consumer_logger]
          ActiveRecord::Base.logger = Rails.logger = @options[:consumer_logger].call(consumer_config)
          Rails.logger
        end
        Rails.logger.info("Starting #{consumer_config.class_name}")

        consumer_thread = Thread.new do
          puts "#{consumer_config.class_name} thread #{Thread.current} forked"
          consumer_config.class_name.constantize.consume(:logger => Rails.logger)
        end
        consumer_threadgroups[consumer_config.name].push(consumer_thread)
        consumer_thread.instance_variable_get :@thread_id
      end

      def call_hook(name)
        if @options[name]
          @options[name].respond_to?(:call) ? instance_eval(&@options[name]) : @options[name]
        end
      end

      def consumer_threadgroups
        @consumer_threadgroups ||= ConsumerGroups.new
      end

      class ConsumerGroups
        def [](consumer_name)
          @threadgroups ||= Hash.new { |hash, key| hash[key] = [] }
          @threadgroups[consumer_name].keep_if{|thread| thread.alive?}
        end
      end
    end



  end
end

