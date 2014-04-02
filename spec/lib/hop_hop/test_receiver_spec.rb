require 'spec_helper'

describe HopHop::TestReceiver do
  let(:blogic) { double }
  let(:consumer) {
    Class.new(HopHop::Consumer) do
      bind "career.test3"
      queue "career_queue_test"

      def consume(event,info)
        options[:blogic].event(event,info)
      end
    end
  }
  it "should receive an event" do
    now=Time.now
    blogic.should_receive(:event) do |event,info|
      event.data.should == {:ok => :foo}
      event.context.should == :context
      event.producer.should == 'recruiting'
      event.version.should == 1
      info.message_count.should == 3
    end
    consumer.consume(:blogic => blogic)
    consumer.receiver.receive_event({:ok => :foo}, {:headers => {:producer => 'recruiting'}}, :context)
  end
end