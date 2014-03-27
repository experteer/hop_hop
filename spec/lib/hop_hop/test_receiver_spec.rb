require 'spec_helper'

describe HopHop::TestReceiver do
  let(:blogic) { double }
  let(:consumer) {
    Class.new(HopHop::Consumer) do
      bind "career.test3"
      queue "career_queue_test"

      def consume(event)
        options[:blogic].event(event)
      end
    end
  }
  it "should receive an event" do
    now=Time.now
    blogic.should_receive(:event) do |event|
      event.data.should == {:ok => :foo}
      event.context.should == :context
      event.producer.should == 'recruiting'
      event.version.should == 1

    end
    consumer.consume(:blogic => blogic)
    consumer.receiver.receive_event({:ok => :foo}, {:headers => {:producer => 'recruiting'}}, :context)
  end
end