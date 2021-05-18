# frozen_string_literal: true

require_relative '../helper/connection_helper'

# SignedUrl class
class Volcanic::Imageman::V1::S3SignedUrl
  include Volcanic::Imageman::ConnectionHelper

  attr_accessor :url, :fields

  # +url+ a string of s3 presigned url
  # +fields+ fields can be anything that is required by the s3 presigned url
  def initialize(url:, **fields)
    raise ArgumentError, 'Expect an url, got nil' if url.nil?

    @url = url
    @fields = fields
  end

  def build_body(**opts)
    fields.update(opts).compact
  end

  def upload(file)
    conn.post(url) do |req|
      req.headers = { 'Content-Type' => 'multipart/form-data' }
      req.body = build_body('Content-Type': file.content_type, file: file.read)
    end
  end
end
