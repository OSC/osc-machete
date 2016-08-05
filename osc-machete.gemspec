# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'osc/machete/version'

Gem::Specification.new do |spec|
  spec.name          = "osc-machete"
  spec.version       = OSC::Machete::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Eric Franz"]
  spec.email         = ["efranz@osc.edu"]
  spec.summary       = "Common interface for working with HPC batch jobs (currently OSC specific)"
  spec.description   = "Common interface for PBS (and eventually other resource managers and batch schedulers - currently OSC specific)"
  spec.homepage      = "https://github.com/OSC/osc-machete"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '~> 2.2'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "minitest", ">= 5.0"

  spec.add_runtime_dependency "mustache"
  spec.add_runtime_dependency "pbs", "~> 2.0"
end

