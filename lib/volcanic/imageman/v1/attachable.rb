# frozen_string_literal: true

require 'base64'
require 'marcel'

# TODO: need to have spec file
# Image class
class Volcanic::Imageman::V1::Attachable
  attr_reader :attachable

  def initialize(attachable, filename: nil, content_type: nil)
    raise ArgumentError, 'Expect value of attachable, got nil' if attachable.nil?

    @filename = filename
    @content_type = content_type
    @attachable = attachable.respond_to?('path') ? attachable : create_readable_file(attachable)
  end

  def read
    File.read(attachable.path)
  end

  def read_as_base64
    Base64.strict_encode64(read)
  end

  def size
    attachable.size
  end

  def size_at_base64
    read_as_base64.size
  end

  def filename
    @filename ||= attachable.original_filename if attachable.respond_to?('original_filename')
  end

  def content_type
    @content_type ||= Marcel::MimeType.for File.open(attachable.path), name: filename
  end

  private

  def create_readable_file(value)
    Tempfile.open do |tmp|
      tmp.write value
      tmp
    end
  end
end
