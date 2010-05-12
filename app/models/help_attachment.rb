class HelpAttachment < ActiveRecord::Base
  
  has_attachment :max_size => 20.megabyte
  
  validates_as_attachment
  
  belongs_to :help_document
  
end
