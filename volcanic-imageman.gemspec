# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'volcanic/imageman/version'

Gem::Specification.new do |spec|
  spec.name          = 'volcanic-imageman'
  spec.version       = Volcanic::Imageman::VERSION
  spec.authors       = %w(Farid)
  spec.email         = %w(faridul.azmi@theaccessgroup.com)
  spec.required_ruby_version = '>= 2.7'

  spec.summary       = 'Ruby gem client for Volcanic Imageman'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/volcanic-uk/imageman-ruby-gem'
  spec.files         = Dir.glob 'lib/**/*.rb'
  spec.require_paths = %w(lib)

  spec.add_dependency 'activesupport'
  spec.add_dependency 'faraday', '~> 1.0'
  spec.add_dependency 'faraday_middleware', '~> 1.0'
  spec.add_dependency 'marcel', '~> 1.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.3'
  spec.add_development_dependency 'rubocop', '~> 0.57.2'
end
