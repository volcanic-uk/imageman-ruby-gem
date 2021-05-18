# frozen_string_literal: true

require_relative 'middleware'
require 'securerandom'

module Volcanic::Imageman::Middleware
  # RequestId
  class RequestId
    def initialize(app = nil)
      @app = app
    end

    def call(request_env)
      request_env[:request_headers]['x-request-id'] ||= request_id

      @app.call(request_env)
    end

    private

    def request_id
      SecureRandom.uuid
    end
  end
end
