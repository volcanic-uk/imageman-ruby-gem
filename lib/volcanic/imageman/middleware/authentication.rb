# frozen_string_literal: true

require 'forwardable'
require_relative 'middleware'

module Volcanic::Imageman::Middleware
  # authentication middleware
  class Authentication
    extend Forwardable

    def_delegators 'Volcanic::Imageman::Configuration'.to_sym, :authentication, :domain_url

    def initialize(app = nil)
      @app = app
    end

    def call(env)
      if request_to_imageman(env[:url])
        env[:request_headers]['Authorization'] ||= auth_key
      else
        env[:request_headers]&.delete('Authorization')
      end

      @app.call(env)
    end

    private

    def auth_key
      @auth_key ||= begin
        "Bearer #{authentication.respond_to?('call') ? authentication.call : authentication}"
      end
    end

    def request_to_imageman(url)
      URI(domain_url).host == url&.host
    end
  end
end
