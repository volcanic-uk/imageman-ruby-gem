# frozen_string_literal: true

require 'forwardable'
require_relative 'middleware'

module Volcanic::Imageman::Middleware
  # authentication middleware
  class Authentication
    extend Forwardable

    def_delegator 'Volcanic::Imageman::Configuration'.to_sym, :authentication

    def initialize(app = nil)
      @app = app
    end

    def call(request_env)
      request_env[:request_headers]['Authorization'] ||= auth_key

      @app.call(request_env)
    end

    private

    def auth_key
      @auth_key ||= begin
        "Bearer #{authentication.respond_to?('call') ? authentication.call : authentication}"
      end
    end
  end
end
