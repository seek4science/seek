class Worksheet < ApplicationRecord

  belongs_to :content_blob, inverse_of: :worksheets
  validates_numericality_of :last_column, :greater_than => 0
  validates_numericality_of :last_row,    :greater_than => 0
end
