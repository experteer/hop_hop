require 'spec_helper'

describe HopHop::Consumer do
  let(:callback) { double }
  let(:consumer) {
    Class.new(HopHop::Consumer) do
      bind :career
      bind "career.test2", "career.test3"
      queue "career_queue_test"

      def on_init
        options[:callback].setup_ok
      end
      
      def on_bind
      end
      
      def on_error(exeption)
      end

    end
  }
  it "should set the bindings" do
    consumer.bind.should == ["career", "career.test2", "career.test3"]
  end

  it "should set the queue" do
    consumer.queue.should == 'career_queue_test'
  end

  it "should call on_init on init (implizit testing options)" do
    callback.should_receive(:setup_ok)
    consumer.new(:callback => callback)
  end


end
