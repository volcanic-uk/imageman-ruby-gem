# frozen_string_literal: true

require 'forwardable'
require_relative 'middleware'
require_relative 'helper'

module Volcanic::Imageman::Middleware
  # authentication middleware
  class Authentication
    extend Forwardable
    include Helper

    def_delegators 'Volcanic::Imageman::Configuration'.to_sym, :authentication

    def initialize(app = nil)
      @app = app
    end

    def call(env)
      if domain_url? env[:url]
        env[:request_headers]['Authorization'] ||= auth_key
      else
        env[:request_headers]&.delete('Authorization')
      end

      @app.call(env)
    end

    private

    def auth_key
      @auth_key ||= "Bearer #{authentication.respond_to?('call') ? authentication.call : authentication}"
    end
  end
end
