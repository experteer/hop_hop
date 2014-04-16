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
    now = Time.now
    blogic.should_receive(:event) do |event, info|
      event.data.should == { :ok => :foo }
      event.context.should == :context
      event.producer.should == 'recruiting'
      event.version.should == 1
      info.message_count.should == 3
    end
    consumer.consume(:blogic => blogic)
    consumer.receiver.receive_event({ :ok => :foo }, { :headers => { :producer => 'recruiting' } }, :context)
  end

  it "should callback on_error on an exception" do
    consumer_instance = consumer.consume
    consumer_instance.should_receive(:on_error) do |exception|
      exception.message.should == "ups"
    end
    consumer.receiver.receive_event({ :error => true }, { :headers => { :producer => 'recruiting' } }, :context)
  end
end
