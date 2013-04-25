# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stormfly/image/version'

Gem::Specification.new do |spec|
  spec.name          = "stormfly-image"
  spec.version       = StormFly::Image::VERSION
  spec.authors       = ["Alejandro Martinez Ruiz"]
  spec.email         = ["alex@nowcomputing.com"]
  spec.description   = %q{Tools for generating, managing and burning StormFly images}
  spec.summary       = %q{Tools for generating, managing and burning StormFly images}
  spec.homepage      = ""
  spec.license       = "Proprietary"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_dependency "uuid", "~> 2.3.7"
end
