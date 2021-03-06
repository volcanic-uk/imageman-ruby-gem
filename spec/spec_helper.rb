# frozen_string_literal: true

require 'bundler/setup'
require 'rspec/its'
require 'json'
require 'volcanic/imageman'
require 'base64'
require 'tempfile'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # example of configuring Imageman client
    Volcanic::Imageman.configure do |configure|
      configure.domain_url = 'http://imageman-domain.com'
      configure.asset_image_url = 'http://asset-image-url.com'
      configure.service = 'test-service'
      configure.authentication = 'api_key'
    end
  end
end
