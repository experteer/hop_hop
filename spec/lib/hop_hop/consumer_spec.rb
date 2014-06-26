require 'spec_helper'

class ConsumerA < HopHop::Consumer
  bind "career.consumerA"
end
class ConsumerB < ConsumerA
  bind "career.consumerB"
end
class ConsumerC < ConsumerB
  bind "career.consumerC"
end

describe HopHop::Consumer do
  let(:callback){ double }
  let(:consumer) do
    Class.new(HopHop::Consumer) do
      bind :career
      bind "career.test2", "career.test3"
      queue "career_queue_test"
      before_filter :foo
      before_filter :foo, "bar"
      def on_init
        options[:callback].setup_ok
      end

      def on_bind
      end

      def on_error(_exeption)
      end

    end
  end
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

  it 'should maintain before_filter' do
    consumer.before_filters.should == [ :foo, :bar ]
  end

  context "on inheritance" do
    let(:inherited_consumer) do
      Class.new(consumer) do
        bind "career.test4"
      end
    end
    it "should inherit the bindings from the parent class" do
      ["career", "career.test2", "career.test3"].each do |b|
        expect(inherited_consumer.bind).to include(b)
      end
    end
    it "should be set the bindings from the class itself" do
      expect(inherited_consumer.bind).to include("career.test4")
    end
    it "should inherit the queue from the parent class" do
      expect(inherited_consumer.queue).to eql("career_queue_test")
    end
    it "should not change bindings on the parent class" do
      consumer # because let is lazy
      expect do
        Class.new(consumer) do
          bind "career.test4"
        end
      end.to_not change{ consumer.bind }
    end

    # 1.8.7 does some wierd things with the inherited callback on dynamically
    # created classes so run some more tests on static classes
    it "should set bindings for ConsumerA" do
      expect(ConsumerA.bind).to eql(["career.consumerA"])
    end
    it "should set bindings for ConsumerB" do
      expect(ConsumerB.bind).to include("career.consumerB")
    end
    it "should inherit bindings for ConsumerB from ConsumerA" do
      expect(ConsumerB.bind).to include("career.consumerA")
    end
    it "should set bindings for ConsumerC" do
      expect(ConsumerC.bind).to include("career.consumerC")
    end
    it "should inherit bindings for ConsumerC from ConsumerA & ConsumerB" do
      expect(ConsumerC.bind).to include("career.consumerA")
      expect(ConsumerC.bind).to include("career.consumerB")
    end

  end

end
