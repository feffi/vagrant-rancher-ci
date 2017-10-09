# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-rancher-v3/version'

Gem::Specification.new do |spec|
  spec.name          = 'vagrant-rancher-v3'
  spec.version       = VagrantPlugins::Rancher::VERSION
  spec.authors       = ['feffi']
  spec.email         = ['feffi@feffi.org']

  spec.summary       = 'Vagrant plugin to bootstrap a Rancher 2.x kubernetes environment.'
  spec.description   = 'Vagrant plugin to install a Rancher server and add k8s nodes all through Vagrant.'
  spec.homepage      = 'https://github.com/feffi/vagrant-rancher-ci'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib', 'locales']

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
end
