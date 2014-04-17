require 'spec_helper'

describe HopHop::TestReceiver do
  let(:blogic){ double }
  let(:consumer) do
    Class.new(HopHop::Consumer) do
      bind "career.test3"
      queue "career_queue_test"

      def consume(event, info)
        case
        when event.data[:error]
          raise "ups"
        when event.data[:exit]
          exit_loop
        else
          options[:blogic].event(event, info)
        end
      end
    end
  end
  it "should receive an event" do
    blogic.should_receive(:event) do |event, info|
      expect(event.data).to eql(:ok => :foo)
      expect(event.context).to eql(:context)
      expect(event.producer).to eql('recruiting')
      expect(event.version).to eql(1)
      expect(info.message_count).to eql(3)
    end
    consumer.consume(:blogic => blogic)
    consumer.receiver.receive_event({ :ok => :foo },
                                    { :headers => { :producer => 'recruiting' } },
                                    :context)
  end

  it "should callback on_error on an exception" do
    consumer_instance = consumer.consume
    consumer_instance.should_receive(:on_error) do |exception|
      expect(exception.message).to eql("ups")
    end
    consumer.receiver.receive_event({ :error => true },
                                    { :headers => { :producer => 'recruiting' } },
                                    :context)
  end
end
