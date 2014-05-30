class TestHooks
  attr_reader :options, :cmd_before, :cmd_after

  def setup_fork(options)
    @options = options
  end

  def before_fork(cmd)
    @cmd_before = cmd
  end

  def after_fork(cmd)
    @cmd_after = cmd
  end
end
self.hop_hop_config = {
  :server_config => { :hooks => TestHooks.new, :log => "hop_hop.log" },
  :port          => 8786,
  :identifier    => "hop_hop_WEORISDFKLwmroiwequ",
  :wait_spinup   => 10,
  :env           => { "test" => [] }
}
