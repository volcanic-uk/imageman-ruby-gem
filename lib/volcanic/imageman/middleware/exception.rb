# frozen_string_literal: true

require_relative 'middleware'
require_relative 'helper'
require 'active_support/core_ext/hash'

module Volcanic::Imageman::Middleware
  # Exception
  class Exception
    include Helper

    def initialize(app = nil)
      @app = app
    end

    def call(env)
      @app.call(env).on_complete do |response|
        status_code = response[:status].to_i
        body = resolve_body(response[:body])
        case status_code
        when 400..410
          error = build_standard_error(body)
          exception = resolve_exception(error[:error_code], status_code, env)
          raise(exception || Volcanic::Imageman::ImageError, error.to_json)
        when 500
          raise Volcanic::Imageman::ServerError, build_server_error(body)
        end
      end
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    def resolve_exception(error_code, status_code, env)
      return Volcanic::Imageman::S3SignedUrlError unless domain_url?(env[:url])

      case status_code
      when 400
        case error_code
        when 1002
          Volcanic::Imageman::DuplicateImage
        when 1003
          Volcanic::Imageman::FileNotSupported
        end
      when 403
        Volcanic::Imageman::Forbidden
      when 404
        Volcanic::Imageman::ImageNotFound
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def build_standard_error(body)
      error = {
        request_id: body.delete('request_id'),
        message: body.delete('message'),
        reason: body.delete('reason'),
        status_code: body.delete('httpStatusCode'),
        error_code: body.delete('errorCode')
      }.compact

      error.empty? ? body : error
    end

    def build_server_error(body)
      {
        request_id: body.delete('request_id'),
        message: 'Server error, Please contact Imageman service support/team',
        status_code: 500
      }
    end

    def resolve_body(body)
      JSON.parse(body)
    rescue JSON::ParserError
      begin
        Hash.from_xml(body)
      rescue REXML::ParseException
        {}
      end
    end
  end
end
