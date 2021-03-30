# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'forwardable'

Dir[File.join(__dir__, 'middleware', '*.rb')].sort.each { |file| require file }

module Volcanic::Imageman
  # connection
  class Connection
    extend Forwardable

    attr_accessor :conn

    def_delegators 'Volcanic::Imageman::Configuration'.to_sym, :domain_url
    def_delegators :conn, :get, :post, :delete, :put

    def initialize
      @conn = Faraday.new(url: domain_url) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/, parser_options: { symbolize_names: true }
        conn.adapter Faraday.default_adapter

        conn.use Faraday::Response::Logger
        conn.use Volcanic::Imageman::Middleware::UserAgent
        conn.use Volcanic::Imageman::Middleware::Authentication
        conn.use Volcanic::Imageman::Middleware::RequestId
        conn.use Volcanic::Imageman::Middleware::Exception
      end
    end
  end
end
