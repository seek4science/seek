class Worksheet < ActiveRecord::Base

  belongs_to :spreadsheet
  belongs_to :content_blob, inverse_of: :worksheets
  has_many :cell_ranges
  validates_numericality_of :last_column, :greater_than => 0
  validates_numericality_of :last_row,    :greater_than => 0
end
