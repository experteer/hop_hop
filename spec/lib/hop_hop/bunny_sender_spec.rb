require 'spec_helper'
require 'json'

describe HopHop::QueueConnection, :rabbitmq do
  it "should retry if connection is closed" do
    sender=HopHop::BunnySender.new
    sender.publish({ :ok => 1},{})
    connection=sender.send(:connection) #I now this a dirty way to get the connection
    connection.close
    expect do sender.publish({ :ok => 1},{}) end.not_to raise_error
  end
end