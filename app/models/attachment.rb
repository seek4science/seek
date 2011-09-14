class Attachment < ActiveRecord::Base

  ATTACHMENT_STORAGE_PATH = 'public/attachments_fu'

  belongs_to :attachable, :polymorphic => true

  has_attachment :storage => :file_system,
                 :path_prefix => ATTACHMENT_STORAGE_PATH,
                 :max_size => 100.gigabytes,
                 :thumbnails => { :thumb => [200, 150], :geometry => 'x50' }

  #include all image types,but attachment.image? with content types defined in attachment_fu,e.g. tif image not included
  def is_image?
    self.content_type.index('image')== 0
  end


end
