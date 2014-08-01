# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/amqp/version'

Gem::Specification.new do |spec|
  spec.name          = "jackalope"
  spec.version       = Rack::AMQP::VERSION
  spec.authors       = ["Joshua Szmajda", "John Nestoriak"]
  spec.email         = ["josh@optoro.com"]
  spec.description   = %q{AMQP-HTTP compliant Server for Rack applications}
  spec.summary       = %q{AMQP-HTTP compliant Server for Rack applications}
  spec.homepage      = "http://github.com/rack-amqp/jackalope"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"
  spec.add_dependency "amqp"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "emoji-rspec"
end
