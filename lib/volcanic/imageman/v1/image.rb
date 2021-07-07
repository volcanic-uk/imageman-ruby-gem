# frozen_string_literal: true

require_relative '../helper/connection_helper'
require_relative '../helper/serialize_helper'
require_relative 'image_class_method'

# Image class
class Volcanic::Imageman::V1::Image
  include Volcanic::Imageman::ConnectionHelper
  include Volcanic::Imageman::SerializeHelper
  extend Volcanic::Imageman::Image::ClassMethod

  UPDATABLE_ATTR = %i(name cacheable cache_duration).freeze
  NON_UPDATABLE_ATTR = %i(id reference uuid creator_subject versions created_at updated_at).freeze
  API_PATH = '/api/v1/images'

  attr_accessor(*UPDATABLE_ATTR)
  attr_reader(*NON_UPDATABLE_ATTR)

  def initialize(**attrs)
    write_self(attrs)
  end

  def reload
    return false unless persisted?

    res = conn.get(persisted_path)
    write_self(serialize_img(res.body))
  end

  def delete
    return false unless persisted?

    conn.delete(persisted_path) && true
  end

  def update(attachable = nil, using_signed_url: false, declared_type: nil, **opts)
    return false unless persisted?

    file = attachable.nil? ? nil : resolve_file(attachable, declared_type)
    body = { reference: nil, path: persisted_path, **opts }
    if using_signed_url || exceed_byte_size(file&.size_at_base64)
      signed_url = build_signed_url(type: file&.content_type, **body)
      signed_url.upload file
    else
      create_or_update(path: persisted_path, file: file&.read_as_base64, **body)
    end
    true
  end

  def persisted?
    !(uuid || reference).nil?
  end

  # Dont use this method, use class method +create+ instead
  def _upload_and_create(attachable, using_signed_url: false, declared_type: nil)
    file = resolve_file(attachable, declared_type)
    if using_signed_url || exceed_byte_size(file.size_at_base64)
      signed_url = build_signed_url(type: file.content_type)
      signed_url.upload file
    else
      create_or_update(file: file.read_as_base64)
    end
  end

  private

  attr_writer(*NON_UPDATABLE_ATTR)

  def write_self(**attrs)
    (UPDATABLE_ATTR + NON_UPDATABLE_ATTR).each do |key|
      send("#{key}=", attrs[key])
    end
    true
  end

  def persisted_path
    "#{API_PATH}/#{uuid || reference}"
  end

  def resolve_file(attachable, declared_type = nil)
    att = attachable
    filename = nil
    content_type = declared_type

    if attachable.is_a?(Hash)
      att = attachable.fetch(:io)
      filename = attachable[:filename]
      content_type = attachable[:content_type] || declared_type
    end

    Volcanic::Imageman::V1::Attachable.new(att, filename: filename, content_type: content_type)
  end

  def default_body
    {
      fileName: name,
      reference: reference,
      cache_duration: cache_duration,
      cacheable: cacheable
    }.compact
  end

  def exceed_byte_size(size)
    return false unless size.is_a? Integer

    size > megabytes_of(3)
  end

  def megabytes_of(number)
    number * 1024 * 1024
  end

  def build_signed_url(type:, **body)
    res = create_or_update(sign_url_enable: true, content_type: type, **body)
    args = res.body[:signed_url] || {}
    Volcanic::Imageman::V1::S3SignedUrl.new(url: args[:url], **args[:fields])
  end

  def create_or_update(path: API_PATH, file: nil, **body)
    response = conn.post(path) do |req|
      req.body = default_body.merge(file: file, **body).compact
    end
    response.tap { |res| write_self(serialize_img(res.body)) }
  end
end
