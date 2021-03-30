# frozen_string_literal: true

module Volcanic::Imageman
  module Image
    # class method for Image
    module ClassMethod
      def create(attachable:, reference: nil, name: nil, cache_duration: nil, cacheable: true, **opts)
        img_ref, img_name = resolve_details(reference, name)
        new(
          name: img_name,
          reference: img_ref,
          cache_duration: cache_duration,
          cacheable: cacheable
        ).tap do |img|
          img._upload_and_create(attachable, **opts)
        end
      end

      def fetch_by(reference: nil, uuid: nil)
        validate_persisted_var(reference, uuid)
        new(reference: resolve_reference(reference), uuid: uuid).tap(&:reload)
      end

      def update(attachable: nil, reference: nil, uuid: nil, **opts)
        validate_persisted_var(reference, uuid)
        new(reference: resolve_reference(reference), uuid: uuid).update(attachable, **opts)
      end

      def delete(reference: nil, uuid: nil)
        validate_persisted_var(reference, uuid)
        new(reference: resolve_reference(reference), uuid: uuid).delete
      end

      private

      def validate_persisted_var(ref, uuid)
        raise ArgumentError, 'Expect either reference or uuid, both got nil' if ref.nil? && uuid.nil?
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

      def resolve_reference(ref)
        ref.is_a?(Volcanic::Imageman::V1::Reference) ? ref.md5_hash : ref
      end
    end
  end
end
