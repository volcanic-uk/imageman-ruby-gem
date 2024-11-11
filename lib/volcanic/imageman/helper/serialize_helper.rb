# frozen_string_literal: true

# Helper function
module Volcanic::Imageman
  # serialize response
  module SerializeHelper
    def serialize_img(**body)
      body.tap do |image|
        image[:uuid] = image.delete :UUID
        image[:name] = image.delete :fileName
        image[:versions] = image[:versions]&.map do |ver|
          Volcanic::Imageman::V1::Version.new(**ver)
        end
      end
    end
  end
end
