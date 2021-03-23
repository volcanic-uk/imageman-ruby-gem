# frozen_string_literal: true

require_relative 'lib/volcanic/imageman/version'

Gem::Specification.new do |spec|
  spec.name          = 'volcanic-imageman'
  spec.version       = Volcanic::Imageman::VERSION
  spec.authors       = %w(Farid)
  spec.email         = %w(faridul.azmi@theaccessgroup.com)
  spec.required_ruby_version = '~> 2.5'

  spec.summary       = 'Ruby gem client for Volcanic Imageman'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/volcanic-uk/imageman-ruby-gem'
  spec.files         = Dir.glob 'lib/**/*.rb'
  spec.require_paths = %w(lib)

  spec.add_dependency 'faraday', '~> 1.0'
  spec.add_dependency 'faraday_middleware', '~> 1.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '~> 1.3'
  spec.add_development_dependency 'rubocop'
end
