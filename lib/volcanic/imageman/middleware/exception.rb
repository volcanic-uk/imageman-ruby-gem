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
          error = standard_error(response)
          exception = resolve_exception(error[:error_code], status_code)
          raise(exception || Volcanic::Imageman::ImageError, error)
        when 500
          raise Volcanic::Imageman::ServerError, server_error(response)
        end
      end
    end

    private

    def resolve_exception(error_code, status_code)
      case status_code
      when 400
        case error_code
        when 1002
          Volcanic::Imageman::DuplicateImage
        when 1003
          Volcanic::Imageman::FileNotSupported
        end
      when 404
        Volcanic::Imageman::ImageNotFound
      end
    end

    def standard_error(response)
      body = resolve_body(response[:body])
      {
        request_id: body.delete('request_id'),
        message: body.delete('message'),
        reason: body.delete('reason'),
        status_code: body.delete('httpStatusCode'),
        error_code: body.delete('errorCode')
      }.compact
    end

    def server_error(response)
      body = resolve_body(response[:body])
      {
        request_id: body.delete('request_id'),
        message: 'Server error, Please contact Imageman service support/team',
        status_code: 500
      }
    end

    def resolve_body(body)
      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end
  end
end
