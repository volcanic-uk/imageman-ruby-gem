# frozen_string_literal: true

require_relative 'middleware'

module Volcanic::Imageman::Middleware
  # middleware helper
  module Helper
    def domain_url?(uri)
      URI(Volcanic::Imageman.configure.domain_url).host == uri&.host
    end
  end
end
