require 'spec_helper'
require 'json'

describe HopHop::QueueConnection, :rabbitmq do

  subject(:sender){ HopHop::BunnySender.new.tap{|s| s.reset}}
  def sender_connection; sender.send(:connection) end # I know this a dirty way to get the connection
  def sender_publishes_msg; sender.publish({ :ok => 1 }, {})  end

  it "should retry if connection is closed" do
    sender_connection.close
    expect{sender_publishes_msg}.not_to raise_error
  end

  it "raises error if connection still not working after reset" do
    allow(sender).to receive(:reset).and_return(nil)
    sender_connection.close
    expect{sender_publishes_msg}.to raise_exception
    expect(sender).to have_received(:reset).exactly(HopHop::BunnySender::RETRIES_AFTER_FAILURE).times
  end

end
