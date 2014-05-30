require 'spec_helper'

describe HopHop::ConsumersConfig do
  let(:config_name)do
    fixture_path("config_hop_hop.rb")
  end

  let(:config) do
    HopHop::ConsumersConfig.load(config_name, 'test')
  end
  it "should load a config file" do
    config
  end

  it "should set wait_spinup" do
    expect(config.wait_spinup).to eq(10)
  end

  it "should set identifier" do
    expect(config.identifier).to eq("test-hop_hop_WEORISDFKLwmroiwequ")
  end
end
