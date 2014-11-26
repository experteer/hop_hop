module HopHop
  module Drivers
    class BaseDriver
      def initialize(&block)
        raise "no configuration block given" unless block_given?
        @options = {}

        instance_eval(&block) # this runs the driver local DSL
      end

      def valid?
        raise "no implementation"
      end

      def root
      end
      # def do_setup
      #  options[:setup].call
        # redirect_output
        # logger.info("Starting HopHop Consumer server")
      # end

      # def run(cmd, options)
      #  require cmd[:consumer_filename]
      #  # run the consumer and give it a logger
      #  Rails.logger = consumer_logger(cmd)
      #  ActiveRecord::Base.logger = Rails.logger
      #  cmd[:class_name].constantize.consume(cmd[:args].merge(:logger => Rails.logger))
      # end
      # def logger
      #  @logger ||= DLog.configure do |l|
      #    filename = Rails.root.join("log", "hop_hop", @options[:log]).to_s
      #    l.level = Rails.logger.level
      #    l.processor(:datefile,
      #                :filename => filename,
      #                :formatter => DLog::Formatter.new('%d [%5p] %m', "%H:%M:%S")
      #    )
      #
      #  end
      # end
    end
  end
end