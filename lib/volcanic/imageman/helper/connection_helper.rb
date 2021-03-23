# frozen_string_literal: true

require_relative '../connection'

# Helper function
module Volcanic::Imageman
  # connection helper
  module ConnectionHelper
    attr_writer :conn

    def self.included(klass)
      klass.extend self
    end

    def conn
      @conn ||= Volcanic::Imageman::Connection.new
    end
  end
end
