class Attachment < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true

  has_attachment :storage => :file_system,
                 :path_prefix => 'public/uploads',
                 :max_size => 10.megabyte,
                 :thumbnails => { :thumb => [400, 300], :geometry => 'x50' }


end
