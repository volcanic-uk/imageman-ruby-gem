# frozen_string_literal: true

require_relative 'middleware'

module Volcanic::Imageman::Middleware
  # middleware for user agent header
  class UserAgent
    def initialize(app = nil)
      @app = app
      @user_agent = "Imageman v#{Volcanic::Imageman::VERSION}"
    end

    def call(request_env)
      request_env[:request_headers]['user-agent'] = @user_agent

      @app.call(request_env)
    end
  end
end
