module HopHop
  # This class represents an event that can be sent through a sender. Don't use this directly.
  # Please inherit and override #producer_postfix.
  class Event
    # set this to hostname.pid in your bootup/environment config
    def self.producer_prefix
      @@producer_prefix
    end

    def self.producer_prefix=(prefix)
      @@producer_prefix = prefix
    end
    self.producer_prefix = nil

    # set this to an instance of BunnySender or TestSender depending on your environment see your envorinment files
    def self.sender
      @@sender
    end

    def self.sender=(prefix)
      @@sender = prefix
    end
    self.sender = nil

    # Call this. Don't bother with instance methods
    # @param name String is the name of the event
    # @param version Integer the version of the event
    # @param data Object a jsonifyable object that should be transfered
    def self.send(name, version, data)
      new(name, version, data).send
    end

    # @param name String is the name of the event, it will be prefix with the subsystem
    # @param version Integer the version of the event
    # @param data Object a jsonifyable object that should be transfered
    # @note This doesn't send the event it's just creating it, #send is your friend
    def initialize(name, version, data)
      @name = "#{subsystem}.#{name}"
      @version = version
      @data = data
    end

    attr_reader :version, :name, :data, :sent_at

    # sends this through the sender and sets sent_at
    # @return [HopHop::Event] self
    def send
      @sent_at = Time.now
      sender.publish(data, meta)
      self
    end

    def meta
      {
        routing_key: name,
        persistent: true,
        timestamp: sent_at.to_i,
        headers: { producer: producer,
                   version: version
        }
      }
    end

    def producer
      "#{self.class.producer_prefix}.#{subsystem}"
    end

    private

    # you should override this! in your inherted class
    def subsystem
      'unknown'
    end

    def sender
      self.class.sender
    end
  end
end
