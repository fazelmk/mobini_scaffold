# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mobini_scaffold/version'

Gem::Specification.new do |spec|
  spec.name          = "mobini_scaffold"
  spec.version       = MobiniScaffold::VERSION
  spec.authors       = ["Fazel Mobini Kesheh"]
  spec.email         = ["fazelmk@gamil.com"]
  spec.summary       = "scaffold plus"
  spec.description   = "Scaffold com template melhorado e funcionalidade extra"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
