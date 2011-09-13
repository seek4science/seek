class Attachment < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true

  has_attachment :storage => :file_system,
                 :max_size => 100.gigabytes,
                 :thumbnails => { :thumb => [200, 150], :geometry => 'x50' }

  def is_image?
    self.content_type.index('image')== 0
  end

end
