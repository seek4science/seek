class HelpImage < ApplicationRecord
  # has_attachment :max_size => 2.megabyte,
  #                :thumbnails => { :thumb => '64x64>' },
  #                :content_type => :image,
  #                :storage => :file_system
  #
  # validates_as_attachment
  #
  has_one :content_blob, as: :asset
  belongs_to :help_document

  validate :check_is_image

  def size
    content_blob.file_size
  end

  def filename
    content_blob.original_filename
  end

  private

  def check_is_image
    unless content_blob.is_image?
      errors.add(:base, "Not an image file: #{content_blob.content_type}")
    end
  end
end