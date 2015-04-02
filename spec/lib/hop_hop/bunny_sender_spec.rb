require 'spec_helper'
require 'json'

describe HopHop::QueueConnection, :rabbitmq do
  it "should retry if connection is closed" do
    sender = HopHop::BunnySender.new
    publish_msg_with sender
    connection = sender.send(:connection) # I know this a dirty way to get the connection
    connection.close
    expect{publish_msg_with sender}.not_to raise_error
  end

  def publish_msg_with(sender)
    sender.publish({ :ok => 1 }, {})
  end
end
