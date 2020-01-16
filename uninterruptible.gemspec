# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'uninterruptible/version'

Gem::Specification.new do |spec|
  spec.name          = "uninterruptible"
  spec.version       = Uninterruptible::VERSION
  spec.authors       = ["Dan Wentworth", "Charlie Smurthwaite"]
  spec.email         = ["support@atechmedia.com"]

  spec.summary       = "Zero-downtime restarts for your trivial socket servers"
  spec.description   = "Uninterruptible gives your socket server magic restarting powers. Send your running "\
     "Uninterruptible server USR1 and it will start a brand new copy of itself which will immediately start handling "\
     "new requests while the old server stays alive until all of it's active connections are complete."
  spec.homepage      = "https://github.com/darkphnx/uninterruptible"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
