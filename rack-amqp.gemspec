# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/amqp/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-amqp"
  spec.version       = Rack::AMQP::VERSION
  spec.authors       = ["Joshua Szmajda"]
  spec.email         = ["josh@optoro.com"]
  spec.description   = %q{amqp}
  spec.summary       = %q{amqp}
  spec.homepage      = ""
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
end
