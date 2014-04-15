require 'spec_helper'

describe HopHop::Event do
  before do
    HopHop::Event.producer_prefix = 'hostname.123'
  end

  let(:data) { { integer: 1, string: 'String', array: [1, 2, 3], time: Time.now } }
  let(:data_json) { data.to_json }
  let(:event) { HopHop::Event.new('the.routing.key', 23, data) }

  describe 'header' do
    it 'should have a producer' do
      event.producer.should == 'hostname.123.unknown'
    end
    it 'should have a version' do
      event.version.should == 23
    end
    it 'should have no sent_at as event is not sent' do
      event.sent_at.should be_nil
    end
    it 'should have a name (this will be the routing key) prefix with the subsystem' do
      event.name.should == 'unknown.the.routing.key'
    end
    it 'should have the data to be transfered' do
      event.data.should == data
    end
  end

  describe 'sending' do
    it 'should hit bunny with jsoned data' do
      HopHop::Event.sender.should_receive(:publish).with(event.data, anything)
      event.send
    end

    it 'should set the sent_at' do
      now = Timecop.freeze
      HopHop::Event.sender.should_receive(:publish)
      event.send
      event.sent_at.should == now
    end

    it 'should add the meta data' do
      now = Timecop.freeze
      HopHop::Event.sender.should_receive(:publish).with(anything,
                                                         routing_key: event.name,
                                                         persistent: true,
                                                         timestamp: now.to_i,
                                                         headers: {
                                                           producer: event.producer,
                                                           version: event.version
                                                          }
                                                         )
      event.send
    end

    # it "should json timestamps the right way (iso8601)" do
    #  HopHop::Event.sender.should_receive(:publish) do |data, options|
    #    data.should match(/"time":"#{Regexp.escape(event.data[:time].iso8601)}"/)
    #  end
    #  event.send
    # end

  end

  describe 'testability' do # TODO: I should move this out to HopHop::TestSender specs
    let(:testex) { HopHop::TestSender.new }
    before do
      HopHop::Event.sender = testex
    end
    it 'should store events in an array' do
      event.send
      testex.should_not be_empty
      testex[0].should == [event.data, event.meta]
    end

    it 'should clear the event array' do
      event.send
      testex.size.should == 1
      testex.reset
      testex.should be_empty
    end

  end
end
