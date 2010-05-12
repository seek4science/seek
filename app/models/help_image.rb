class HelpImage < ActiveRecord::Base
  
  has_attachment :max_size => 2.megabyte,
                 :thumbnails => { :thumb => '64x64>' },
                 :content_type => :image,
                 :storage => :file_system
  
  validates_as_attachment
  
  belongs_to :help_document
  
end