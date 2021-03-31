# frozen_string_literal: true

module Volcanic::Imageman
  class ImagemanError < StandardError; end

  class MissingConfiguration < ImagemanError; end

  class ServerError < ImagemanError; end

  # Related to image api
  class ImageError < ImagemanError; end

  class DuplicateImage < ImageError; end

  class ImageNotFound < ImageError; end

  class FileNotSupported < ImageError; end
end
