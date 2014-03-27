require 'spec_helper'

describe HopHop::Consumer do
  let(:callback) { double }
  let(:consumer) {
    Class.new(HopHop::Consumer) do
      bind :career
      bind "career.test2", "career.test3"
      queue "career_queue_test"

      def setup
        options[:callback].setup_ok
      end


    end
  }
  it "should set the bindings" do
    consumer.bind.should == ["career", "career.test2", "career.test3"]
  end

  it "should set the queue" do
    consumer.queue.should == 'career_queue_test'
  end

  it "should call setup on init (implizit testing options)" do
    callback.should_receive(:setup_ok)
    consumer.new(:callback => callback)
  end


end
