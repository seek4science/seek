class HelpAttachment < ApplicationRecord
  # has_attachment :max_size => 20.megabyte
  #
  # validates_as_attachment
  #
  has_one :content_blob, as: :asset
  belongs_to :help_document

  def size
    content_blob.file_size
  end

  def filename
    content_blob.original_filename
  end
end
