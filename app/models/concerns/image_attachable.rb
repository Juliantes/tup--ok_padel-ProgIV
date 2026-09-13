# frozen_string_literal: true

module ImageAttachable
  extend ActiveSupport::Concern

  ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  class_methods do
    def validates_image_attachment(name)
      validates name, content_type: ALLOWED_IMAGE_TYPES,
                     size: { less_than: MAX_IMAGE_SIZE }
    end
  end
end
