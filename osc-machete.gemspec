# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'osc/machete/version'

Gem::Specification.new do |spec|
  spec.name          = "osc-machete"
  spec.version       = OSC::Machete::VERSION
  spec.authors       = ["Eric Franz"]
  spec.email         = ["efranz@osc.edu"]
  spec.description   = "Appkit to interact with HPC resources"
  spec.summary       = "AweSim!"
  spec.homepage      = "http://www.awesim.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "minitest", ">= 5.0"

  spec.add_runtime_dependency "mustache"
  spec.add_runtime_dependency "pbs", "~> 1.0"
end

