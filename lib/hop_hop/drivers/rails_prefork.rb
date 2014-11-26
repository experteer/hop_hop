module HopHop
  module Drivers
    class RailsPrefork < BaseDriver
      def startable?
        true
      end

      def start_server(config, server_ctrl)
        pid = Process.fork do
          cmd = "hop_hop server --identifier #{config.control.identifier}"
          # puts "starting #{cmd}"
          $0 = cmd
          HopHop::ConsumerServer.start(config)
        end

        Process.detach(pid) # so we leave no zombies behind
        HopHop::Helper.wait_unless(config.control.wait_spinup) { !server_ctrl.alive? } # now wait for it to spin up
        raise "Could not spin up the fork server" unless server_ctrl.alive?
      end

      # expect options:
      def valid?
        raise ":rails_root not set for rails_prefork" unless @options[:rails_root]
        raise ":rails_root #{@options[:rails_root]} doesn't exist" unless File.exist?(@options[:rails_root])
      end

      # DSL:
      def setup(&block)
        @options[:setup] = block
      end

      def before_fork(&block)
        @options[:before_fork] = block
      end

      def after_fork(&block)
        @options[:after_fork] = block
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
        puts "starting rails"
        call_hook(:setup)
      end

      def do_logger(config)
        call_hook(:logger)
      end

      def do_stop(config, consumer_config, pid)
        cmd = "kill -TERM #{pid}"
        system(cmd)
        # TBD: wait for process to stop
        pid
      end

      def do_start(config, consumer_config)
        call_hook(:before_fork)
        pid = fork do
          $0 = "hop_hop consumer --identifier #{config.control.identifier} #{consumer_config.name}"
          call_hook(:after_fork)
          run(consumer_config)
        end
        pid
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
        consumer_config.class_name.constantize.consume(logger: Rails.logger)
      end

      def call_hook(name)
        @options[name].call if @options[name]
      end
    end
  end
end