# frozen_string_literal: true

require 'forwardable'
require 'digest'

# Reference
class Volcanic::Imageman::V1::Reference
  extend Forwardable

  def_delegators 'Volcanic::Imageman::Configuration'.to_sym, :asset_image_url, :service

  attr_accessor :opts, :name, :source

  class << self
    def hash(name:, source:, **opts)
      new(name: name, source: source, **opts).md5_hash
    end

    def hash_with_url(name:, source:, **opts)
      new(name: name, source: source, **opts).url
    end
  end

  def initialize(name:, source:, **opts)
    @opts = opts
    @name = name
    @source = source
  end

  def md5_hash
    @md5_hash ||= begin
      args = { name: name, source: source, service: service, **opts }.compact
      sort_keys_return_values = args.sort.to_h.values # sort by key and return value in array
      Digest::MD5.hexdigest(sort_keys_return_values.join(':'))
    end
  end

  def url
    @url ||= "#{asset_image_url}/#{md5_hash}"
  end
end
