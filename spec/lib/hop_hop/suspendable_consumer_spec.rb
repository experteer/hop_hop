require 'spec_helper'
require 'json'

class TestConsumer < HopHop::SuspendableConsumer
  queue "test_queue_test"
  bind "test.test"
  bind "test.term"
  suspend_on "test.stop"
  resume_on "test.cont"

  def consume(event, _info)
puts "\n"
p event
puts "\n"
    options[:events] << event
    if event.name == 'test.term'
      exit_loop
    end
  end

end
class TestEvent < HopHop::Event
  def subsystem
    "test"
  end
end

describe HopHop::SuspendableConsumer, :rabbitmq do
  before(:each) do
    @events = []
    @consumer = TestConsumer.new(:events => @events)
    HopHop::Event.sender = HopHop::BunnySender.new
    @qc = HopHop::QueueConnection.new(@consumer, 
                                      :host => 'localhost', 
                                      :port => 5672, 
                                      :requeue_sleep => 0.1)
    sleep 0.2
  end
  after(:each) do
    HopHop::Event.sender = HopHop::TestSender.new
    qc = HopHop::QueueConnection.new(@consumer, :host => 'localhost', :port => 5672)
    qc.queue.purge
    qc.close
  end

  it 'shoud process messages' do
    TestEvent.send('test', 1, :test => true)
    TestEvent.send('term', 1, :test => true)
    sleep 0.2
    @qc.loop
p @events.map { |e| e.name }
    @events.size.should == 2
    @events.map { |e| e.name }.should == [ "test.test", "test.term" ]
  end

  it 'should suspend and continue' do
    TestEvent.send('stop', 1, :test => true)
    TestEvent.send('test', 1, :test => true)
    TestEvent.send('cont', 1, :test => true)
    TestEvent.send('test', 1, :test => true)
    TestEvent.send('term', 1, :test => true)
    sleep 0.2
    @qc.loop
p @events.map { |e| e.name }
    @events.size.should == 5
    @events.map { |e| e.name }.should == [ "test.test", "test.test", "test.test", "test.test", "test.term" ]
  end

end

