class Worksheet < ActiveRecord::Base

  unloadable

  belongs_to :spreadsheet
  belongs_to :content_blob
  has_many :cell_ranges
  
end
