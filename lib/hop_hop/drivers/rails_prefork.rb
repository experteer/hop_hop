module HopHop
  module Drivers
    class RailsPrefork < BaseDriver
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
        puts "Stopping: #{pid}"
        cmd = "kill -TERM #{pid}"
        system(cmd)

        pid_check = true
        tries = 0
        name_regexp = Regexp.new("--identifier #{config.control.identifier} #{consumer_config.name}")
        res = pid

        while pid_check
          running_pids = Sys::ProcTable.ps.select{|proc| proc.cmdline =~ name_regexp && proc.pid == pid}
          if running_pids.empty?
            pid_check = false
          else
            puts "Waiting for stop: pid: #{pid} consumer: #{ consumer_config.name}"
            tries += 1
            sleep(0.1 * tries) # sleeping .1,.2,.3,.4,.5
            if tries > 10
              pid_check = false
              res = nil
              puts "Stopping pid failed: #{pid}"
            end
          end
        end

        res
      end

      def do_start(config, consumer_config)
        call_hook(:before_fork)
        pid = fork do
          $0 = "hop_hop consumer --identifier #{config.control.identifier} #{consumer_config.name}"
          call_hook(:after_fork)
          run(consumer_config)
        end
        Process.detach(pid) # so we leave no zombies behind
        pid
      end

      def instance_ids(config, consumer_config)
        name_regexp = Regexp.new("--identifier #{config.control.identifier} #{consumer_config.name}")
        tries = 0
        begin
          running_pids = Sys::ProcTable.ps.select{|proc| proc.cmdline =~ name_regexp}.map(&:pid)
          running_pids.sort
        rescue Errno::ENOENT, Errno::EINVAL, Errno::ESRCH
          tries += 1
          sleep(0.1 * tries)
          retry unless tries > 3
          nil
        end
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
        consumer_config.class_name.constantize.consume(:logger => Rails.logger)
      end

      def call_hook(name)
        if @options[name]
          @options[name].respond_to?(:call) ? instance_eval(&@options[name]) : @options[name]
        end
      end
    end
  end
end
