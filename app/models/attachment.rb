class Attachment < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true

  has_attachment :storage => :file_system,
                 :path_prefix => 'public/uploads',
                 :max_size => 10.megabyte,
                 :thumbnails => { :thumb => [400, 300], :geometry => 'x50' }

  def is_image?
    self.content_type.index('image')== 0
  end

end
