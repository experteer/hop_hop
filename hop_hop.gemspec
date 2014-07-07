# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hop_hop/version'

Gem::Specification.new do |spec|
  spec.name          = "hop_hop"
  spec.version       = HopHop::VERSION
  spec.authors       = ["Peter Schrammel"]
  spec.email         = ["peter.schrammel@experteer.com"]
  spec.summary       = %q(HopHop is experteer's binding to rabbitmq)

  spec.description   = %q(HopHop is experteer's binding to rabbitmq)
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}){ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~>10.1.0"
  spec.add_development_dependency "rspec", "2.14.1"
  spec.add_development_dependency "timecop", "0.3.5"

  spec.add_dependency "bunny", "1.3.1"
  spec.add_dependency "sys-proctable", ">=0.9.0"

end
