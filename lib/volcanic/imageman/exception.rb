# frozen_string_literal: true

module Volcanic::Imageman
  class ImagemanError < StandardError; end

  class MissingConfiguration < ImagemanError; end

  class ImageError < ImagemanError; end

  class ServerError < ImagemanError; end
end
