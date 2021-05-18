# frozen_string_literal: true

# configuration
module Volcanic::Imageman
  def self.configure
    yield Volcanic::Imageman::Configuration if block_given?
    Volcanic::Imageman::Configuration
  end

  # configuration class
  class Configuration
    class << self
      attr_accessor :authentication
      attr_writer :domain_url, :asset_image_url, :service

      def domain_url
        raise_missing_for 'domain' if @domain_url.nil?

        @domain_url
      end

      def asset_image_url
        raise_missing_for 'asset_image_url' if @asset_image_url.nil?

        @asset_image_url
      end

      def service
        @service ||= 'volcanic_service'
      end

      private

      def raise_missing_for(name)
        raise Volcanic::Imageman::MissingConfiguration, "#{name} is required to be configured."
      end
    end
  end
end
