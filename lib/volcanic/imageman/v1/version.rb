# frozen_string_literal: true

# Version class
class Volcanic::Imageman::V1::Version
  ATTRIBUTES = %i(id version_id s3_key image_id creator_subject created_at updated_at).freeze
  attr_reader(*ATTRIBUTES)

  def initialize(**args)
    ATTRIBUTES.each do |key|
      instance_variable_set("@#{key}", args[key])
    end
  end
end
