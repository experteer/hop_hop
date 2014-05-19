module HopHop
  class ConsumerConfig
    # instances, name, class_name, args
    def initialize(opts)
      @opts = opts
    end

    def name
      @opts[:name]
    end

    def instances
      @opts[:instances] || 1
    end

    def class_name
      @opts[:class_name]
    end

    def args
      @opts[:args] || {}
    end

    def to_hash
      { :consumer_filename => consumer_filename,
        :class_name        => class_name,
        :args              => args,
        :name              => name
      }
    end

  private

    def consumer_filename
      @opts[:file_name] || HopHop::Helper.underscore(class_name)
    end
  end
end
