require 'spec_helper'

describe HopHop::Config do
  let(:config_name) do
    fixture_path("config_hop_hop.rb")
  end

  let(:config) do
    HopHop::Config.load(config_name, 'test')
  end

  it "should load a config file" do
    config
  end

  it "should set overrides" do
    config = HopHop::Config.load(config_name, 'test', log: "override.log", port: 1111)
    expect(config.control.port).to eq(1111)
    # TODO: test stdout_filename override
  end

  describe "control" do
    it "should set wait_spinup" do
      expect(config.control.wait_spinup).to eq(10)
    end

    it "should set identifier" do
      expect(config.control.identifier).to eq("test-hop_hop_SOMETESTING82348")
    end
  end

  describe "driver" do
    it "should set the driver" do

    end
  end

  describe "consumers" do
    it "should read the consumers configuration" do
      consumers = config.consumers.of_role("background")
      expect(consumers.size).to eq(2)
      config = consumers[0]
      expect(config.class_name).to eq('Recruiting::CareerAdapterConsumer')
      expect(config.name).to eq('recruiting_career_adapter_consumer')
      expect(config.filename).to eq('recruiting/career_adapter_consumer')
      expect(config.role).to eq(:background)
    end

  end

  describe "hosts" do
    it "should read the hosts configuration" do
      expect(config.hosts.roles_of_host('dietrich')).to eq([:indexing])
    end
  end
end
