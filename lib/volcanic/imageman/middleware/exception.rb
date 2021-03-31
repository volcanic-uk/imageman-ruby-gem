# frozen_string_literal: true

require_relative 'middleware'

module Volcanic::Imageman::Middleware
  # Exception
  class Exception
    def initialize(app = nil)
      @app = app
    end

    def call(request_env)
      @app.call(request_env).on_complete do |response|
        status_code = response[:status].to_i
        case status_code
        when 400..410
          error_code = standard_error(response)[:error_code]
          exception = Volcanic::Imageman::ImageError
          exception = Volcanic::Imageman::DuplicateImage if status_code == 400 && error_code == 1002
          exception = Volcanic::Imageman::ImageNotFound if status_code == 404

          raise exception, standard_error(response)
        when 500
          raise Volcanic::Imageman::ServerError, server_error(response)
        end
      end
    end

    private

    def standard_error(response)
      body = JSON.parse(response[:body])
      {
        request_id: body.delete('request_id'),
        message: body.delete('message'),
        reason: body.delete('reason'),
        status_code: body.delete('httpStatusCode'),
        error_code: body.delete('errorCode')
      }.compact
    end

    def server_error(response)
      body = JSON.parse(response[:body])
      {
        request_id: body.delete('request_id'),
        message: 'Server error, Please contact Imageman service support/team',
        status_code: 500
      }
    end
  end
end
