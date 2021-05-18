# frozen_string_literal: true

require_relative '../connection'

# Helper function
module Volcanic::Imageman
  # connection helper
  module ConnectionHelper
    attr_writer :conn

    def conn
      @conn ||= Volcanic::Imageman::Connection.new
    end
  end
end
