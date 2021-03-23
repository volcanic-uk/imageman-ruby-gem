# frozen_string_literal: true

require 'base64'
require_relative '../helper/connection_helper'
require_relative '../helper/serialize_helper'

# Image class
class Volcanic::Imageman::V1::Image
  include Volcanic::Imageman::ConnectionHelper
  include Volcanic::Imageman::SerializeHelper

  UPDATABLE_ATTR = %i(name cacheable cache_duration).freeze
  NON_UPDATABLE_ATTR = %i(id reference uuid creator_subject versions created_at updated_at).freeze
  API_PATH = '/api/v1/images'

  attr_accessor(*UPDATABLE_ATTR)
  attr_reader(*NON_UPDATABLE_ATTR)

  class << self
    def create(attachable:, reference: nil, name: nil, cache_duration: nil, cacheable: true)
      img_ref, img_name = resolve_details(reference, name)
      new(
        name: img_name,
        reference: img_ref,
        cache_duration: cache_duration,
        cacheable: cacheable
      ).tap do |img|
        img._upload_and_create(resolve_file(attachable))
      end
    end

    def fetch_by(reference: nil, uuid: nil)
      raise ArgumentError, 'Expect either reference or uuid, both got nil' unless reference || uuid

      ref = reference.is_a?(Volcanic::Imageman::V1::Reference) ? reference.md5_hash : reference
      new(reference: ref, uuid: uuid).tap(&:reload)
    end

    def delete(reference: nil, uuid: nil)
      raise ArgumentError, 'Expect either reference or uuid, both got nil' unless reference || uuid

      ref = reference.is_a?(Volcanic::Imageman::V1::Reference) ? reference.md5_hash : reference
      new(reference: ref, uuid: uuid).delete
    end

    private

    # return base64 string
    def resolve_file(attachable)
      raise ArgumentError, 'Expect a value attachable, both got nil' if attachable.nil?

      case attachable
      when Hash
        Base64.strict_encode64(attachable.fetch(:io)&.read)
      else
        if attachable.respond_to?('read')
          Base64.strict_encode64(attachable.read)
        else
          attachable # a base64 file
        end
      end
    end

    def resolve_details(ref, name)
      if ref.is_a? Volcanic::Imageman::V1::Reference
        [ref.md5_hash, name || ref.name]
      else
        raise ArgumentError, 'Expected a value of name' unless name
        raise ArgumentError, 'Expected a value of reference' unless ref

        [ref, name]
      end
    end
  end

  def initialize(**attrs)
    write_self(attrs)
  end

  def reload
    return false unless persisted?

    res = conn.get(persisted_path)
    write_self(serialize_img(res.body)) && true
  end

  def delete
    return false unless persisted?

    conn.delete(persisted_path) && true
  end

  def update_file(base_64_string)
    return false unless persisted?

    conn.post(persisted_path) { |req| req.body = { file: base_64_string } }
    true
  end

  def persisted?
    !!(uuid || reference)
  end

  # Dont use this method, use class method +create+ instead
  def _upload_and_create(base_64_string)
    res = conn.post API_PATH do |req|
      req.body = {
        fileName: name,
        file: base_64_string,
        reference: reference,
        cache_duration: cache_duration,
        cacheable: cacheable
      }.compact
    end
    write_self(serialize_img(res.body))
  end

  private

  attr_writer(*NON_UPDATABLE_ATTR)

  def write_self(**attrs)
    (UPDATABLE_ATTR + NON_UPDATABLE_ATTR).each do |key|
      send("#{key}=", attrs[key])
    end
  end

  def persisted_path
    "#{API_PATH}/#{uuid || reference}"
  end
end
